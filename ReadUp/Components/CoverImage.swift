import SwiftUI

/// A imagem de uma capa, com cache em memória por URL.
///
/// Existe porque o `AsyncImage` não tem cache: cada instância recomeça o download do
/// zero e mostra o placeholder enquanto isso. Ao abrir um livro, a mesma capa é
/// desenhada por três instâncias diferentes em sequência (grade → `FlyingCover` →
/// `BookDetailsView`) — daí o piscar entre a capa real e a capa padrão.
///
/// Aqui a leitura do cache é **síncrona**, dentro do `body`: uma URL já baixada
/// aparece já no primeiro frame, sem nunca passar pelo placeholder.
struct CoverImage<Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let placeholder: () -> Placeholder

    /// Guardado junto com a URL de origem: numa célula reciclada da grade, esta view é
    /// reusada com outro livro, e um `UIImage` solto aqui seria a capa do livro anterior.
    @State private var loaded: (url: URL, image: UIImage)?

    private var image: UIImage? {
        guard let url else { return nil }
        if let loaded, loaded.url == url { return loaded.image }
        return CoverImageCache.image(for: url)
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url, CoverImageCache.image(for: url) == nil else { return }
            if let image = await CoverImageCache.load(url) {
                loaded = (url, image)
            }
        }
    }
}

/// Cache em memória das capas já baixadas. `NSCache` porque ele solta sozinho sob
/// pressão de memória — um dicionário nosso cresceria para sempre.
@MainActor
enum CoverImageCache {
    private static let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 200
        return cache
    }()

    /// Downloads em voo, por URL: duas capas iguais na tela baixam uma vez só.
    private static var inFlight: [URL: Task<UIImage?, Never>] = [:]

    static func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    static func load(_ url: URL) async -> UIImage? {
        if let cached = image(for: url) { return cached }

        if let existing = inFlight[url] { return await existing.value }

        let task = Task<UIImage?, Never> {
            guard
                let (data, response) = try? await URLSession.shared.data(from: url),
                let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                let image = UIImage(data: data)
            else { return nil }
            // Decodifica fora da hora de desenhar: sem isto o primeiro frame de scroll
            // paga o custo do JPEG.
            return await image.byPreparingForDisplay() ?? image
        }
        inFlight[url] = task

        let image = await task.value
        inFlight[url] = nil
        if let image { cache.setObject(image, forKey: url as NSURL) }
        return image
    }

    /// Baixa em paralelo as capas que ainda não estão em memória, para que a grade da
    /// biblioteca já apareça com elas prontas. Só ignora o que já está no cache.
    static func warm(_ urls: [URL]) async {
        let missing = Array(Set(urls.filter { image(for: $0) == nil }))
        guard !missing.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for url in missing {
                group.addTask { _ = await load(url) }
            }
        }
    }

    /// Esquece uma capa (a capa do livro mudou; logout).
    static func invalidate(_ url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }

    static func clear() {
        cache.removeAllObjects()
    }
}
