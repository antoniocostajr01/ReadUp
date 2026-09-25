import Foundation

/// Uma versão mais nova do app publicada na App Store.
struct AvailableUpdate: Identifiable, Equatable {
    let version: String
    let storeURL: URL
    var id: String { version }
}

/// Pergunta à App Store se há versão mais nova que a instalada.
///
/// Usa o lookup público do iTunes em vez de um endpoint nosso: o aviso é só opcional,
/// então não precisamos controlar versão mínima, e ninguém precisa lembrar de atualizar
/// uma variável de ambiente a cada release. O lookup pode atrasar algumas horas depois
/// de uma publicação — para um aviso dispensável, tudo bem.
struct AppUpdateService {
    private static let bundleID = "com.antoniocosta.ReadUpApp"

    private struct LookupResponse: Decodable {
        struct Result: Decodable {
            let version: String
            let trackViewUrl: URL
        }
        let results: [Result]
    }

    /// `nil` quando o app está em dia, fora da loja (TestFlight, debug) ou sem rede.
    func availableUpdate() async -> AvailableUpdate? {
        guard let installed = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }
        // `country` é obrigatório na prática: sem ele o lookup só olha a loja americana.
        let region = Locale.current.region?.identifier.lowercased() ?? "br"
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "bundleId", value: Self.bundleID),
            URLQueryItem(name: "country", value: region),
        ]
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        // O CDN da Apple guarda a resposta; sem isto o URLCache local somaria mais atraso.
        request.cachePolicy = .reloadIgnoringLocalCacheData

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let store = try? JSONDecoder().decode(LookupResponse.self, from: data).results.first,
              Self.isVersion(store.version, newerThan: installed) else {
            return nil
        }
        return AvailableUpdate(version: store.version, storeURL: store.trackViewUrl)
    }

    /// Compara por componentes numéricos: "2.10" é mais nova que "2.9".
    static func isVersion(_ candidate: String, newerThan installed: String) -> Bool {
        let lhs = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let rhs = installed.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(lhs.count, rhs.count) {
            let a = i < lhs.count ? lhs[i] : 0
            let b = i < rhs.count ? rhs[i] : 0
            if a != b { return a > b }
        }
        return false
    }
}
