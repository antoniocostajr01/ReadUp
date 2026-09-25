import Foundation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class BookFormViewModel {
    enum Mode {
        case create
        case edit(Book)

        var book: Book? {
            if case .edit(let book) = self { return book }
            return nil
        }
    }

    let mode: Mode

    var title: String
    var author: String
    var pagesText: String
    var isbn: String
    /// Página em que o leitor está começando. 1 = do início. Figma `47:1783`.
    var startingPageText: String
    var details: String
    var status: BookStatus
    var coverImage: UIImage?

    var selectedPhoto: PhotosPickerItem?
    var isSaving = false
    var errorMessage: String?

    /// Base64 comprimido da nova capa, se o usuário trocou; nil = manter a capa atual.
    private var newCoverBase64: String?

    init(mode: Mode) {
        self.mode = mode
        let book = mode.book
        title = book?.title ?? ""
        author = book?.author ?? ""
        pagesText = book.map { $0.numberOfPages > 0 ? String($0.numberOfPages) : "" } ?? ""
        isbn = book?.isbn ?? ""
        startingPageText = book.flatMap { $0.progress.map(String.init) } ?? "1"
        details = book?.details ?? ""
        status = book?.status ?? .iWantToRead
        coverImage = nil
    }

    /// A página inicial nunca passa do total nem cai abaixo de 1.
    var startingPage: Int {
        min(max(Int(startingPageText) ?? 1, 1), max(Int(pagesText) ?? 1, 1))
    }

    var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (Int(pagesText) ?? 0) > 0
    }

    func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        setCover(image)
    }

    /// Nova capa, venha da galeria ou da câmera. Só sobe para o backend ao salvar.
    func setCover(_ image: UIImage) {
        coverImage = image
        newCoverBase64 = image.compressedBase64()
    }

    /// O livro recém-criado no modo `.create` — é ele que a tela de conquista exibe.
    var createdBook: Book?

    @discardableResult
    func save(store: LibraryStore) async -> Bool {
        guard isSaveEnabled else { return false }
        isSaving = true
        defer { isSaving = false }

        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedAuthor = author.trimmingCharacters(in: .whitespaces)
        let trimmedIsbn = isbn.trimmingCharacters(in: .whitespaces)
        let pages = Int(pagesText) ?? 0

        let success: Bool
        switch mode {
        case .create:
            let payload = CreateBookPayload(
                title: trimmedTitle,
                author: trimmedAuthor.isEmpty ? nil : trimmedAuthor,
                totalPages: pages,
                details: details.isEmpty ? nil : details,
                coverUrl: nil,
                status: status.rawValue,
                isbn: trimmedIsbn.isEmpty ? nil : trimmedIsbn,
                coverImage: newCoverBase64
            )
            createdBook = await store.createManualBook(payload)
            success = createdBook != nil
            // `CreateBookPayload` não carrega progresso: quem começa no meio do livro
            // é registado num segundo passo, e só quando não começa da página 1.
            if let created = createdBook, startingPage > 1 {
                await store.updateBook(created, with: UpdateBookPayload(progress: startingPage))
                createdBook = store.books.first { $0.id == created.id } ?? created
            }
        case .edit(let book):
            let payload = UpdateBookPayload(
                title: trimmedTitle,
                author: trimmedAuthor.isEmpty ? nil : trimmedAuthor,
                totalPages: pages,
                details: details.isEmpty ? nil : details,
                status: status.rawValue,
                progress: startingPage,
                isbn: trimmedIsbn.isEmpty ? nil : trimmedIsbn,
                coverImage: newCoverBase64
            )
            success = await store.updateBook(book, with: payload)
        }

        if !success {
            errorMessage = store.errorMessage ?? Localization.BookDetails.saveError.string
        }
        return success
    }
}
