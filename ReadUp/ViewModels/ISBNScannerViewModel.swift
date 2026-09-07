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
        /// `nil` até o usuário escolher — mostra "Select status", não vem pré-marcado.
        var status: BookStatus?
        /// `true` depois de persistido na biblioteca: a linha continua na lista (o
        /// usuário volta pra ela ao tocar "Add another book"), só que não é mais
        /// contada em `foundCount`/`addAll` nem reabre a folha de confirmação.
        var isAdded = false
    }

    var scanned: [ScannedBook] = []

    /// Chamado quando um ISBN termina de resolver (achado ou não) — é o gatilho pra
    /// tela abrir a folha de confirmação (08c/08b) sozinha, sem o usuário precisar
    /// tocar na linha. Todo livro escaneado passa por confirmação explícita.
    var onResolved: ((ScannedBook) -> Void)?

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
            onResolved?(scanned[index])
        }
    }

    func remove(_ book: ScannedBook) {
        scanned.removeAll { $0.id == book.id }
    }

    /// Marca uma linha como persistida sem tirá-la da lista — quem volta pro scanner
    /// depois de "Add another book" precisa ver o que acabou de adicionar.
    func markAdded(_ id: String) {
        guard let index = scanned.firstIndex(where: { $0.id == id }) else { return }
        scanned[index].isAdded = true
    }

    /// Adiciona todos os livros resolvidos (`.found`) e ainda não persistidos à
    /// biblioteca. Devolve os livros criados — a tela de conquista exibe o primeiro.
    ///
    /// Marca cada linha adicionada em vez de removê-la: sem isso o "Add N books"
    /// continuava oferecendo os mesmos livros já salvos, e um segundo toque duplicava
    /// tudo — e a lista perdia o que tinha acabado de ser adicionado.
    func addAll(to store: LibraryStore) async -> [Book] {
        var added: [Book] = []
        for row in scanned {
            guard case .found(let book) = row.state, !row.isAdded else { continue }
            if let created = await store.addBook(from: book, status: row.status ?? .iWantToRead, isbn: row.isbn) {
                added.append(created)
                markAdded(row.id)
            }
        }
        return added
    }
}
