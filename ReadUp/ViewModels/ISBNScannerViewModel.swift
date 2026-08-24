import Foundation
import UIKit

/// Estado da tela de scanner em lote: cada ISBN escaneado vira uma linha que resolve
/// (ou não) num livro, e o usuário escolhe o status antes de adicionar tudo de uma vez.
@MainActor
@Observable
final class ISBNScannerViewModel {
    struct ScannedBook: Identifiable {
        enum State {
            case resolving
            case found(SearchBook)
            case notFound
        }

        var id: String { isbn }
        let isbn: String
        var state: State
        var status: BookStatus = .iWantToRead
    }

    var scanned: [ScannedBook] = []

    private let service: GoogleBooksService
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    init(service: GoogleBooksService = GoogleBooksService()) {
        self.service = service
    }

    /// Chamado a cada código de barras OU texto reconhecido pela câmera. O VisionKit
    /// refaz o callback continuamente enquanto o mesmo item estiver em quadro — dedupar
    /// pelo ISBN já cadastrado em `scanned` é o que impede duplicar a linha.
    func handle(recognized text: String) {
        guard let isbn = ISBN.firstValid(in: text),
              !scanned.contains(where: { $0.isbn == isbn }) else { return }

        // No topo: o último código lido é o que o usuário acabou de mirar, e é ele que
        // precisa conferir na hora. No fim da lista ele sairia da área visível da sheet.
        scanned.insert(ScannedBook(isbn: isbn, state: .resolving), at: 0)
        feedback.impactOccurred()

        // Falha de rede e código desconhecido dão na mesma linha "não encontrado":
        // pro usuário com o livro na mão a diferença não muda o que ele pode fazer.
        Task {
            let book = try? await service.lookupISBN(isbn)
            guard let index = scanned.firstIndex(where: { $0.isbn == isbn }) else { return }
            scanned[index].state = book.map(ScannedBook.State.found) ?? .notFound
        }
    }

    func remove(_ book: ScannedBook) {
        scanned.removeAll { $0.id == book.id }
    }

    /// Adiciona todos os livros resolvidos (`.found`) à biblioteca. Retorna quantos
    /// deram certo — usado pra feedback ("N livros adicionados").
    func addAll(to store: LibraryStore) async -> Int {
        var added = 0
        for row in scanned {
            guard case .found(let book) = row.state else { continue }
            if await store.addBook(from: book, status: row.status, isbn: row.isbn) {
                added += 1
            }
        }
        return added
    }
}
