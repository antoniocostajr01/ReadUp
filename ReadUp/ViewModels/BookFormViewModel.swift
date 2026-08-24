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
        details = book?.details ?? ""
        status = book?.status ?? .iWantToRead
        coverImage = nil
    }

    var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (Int(pagesText) ?? 0) > 0
    }

    func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        coverImage = image
        newCoverBase64 = image.compressedBase64()
    }

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
            success = await store.createManualBook(payload)
        case .edit(let book):
            let payload = UpdateBookPayload(
                title: trimmedTitle,
                author: trimmedAuthor.isEmpty ? nil : trimmedAuthor,
                totalPages: pages,
                details: details.isEmpty ? nil : details,
                status: status.rawValue,
                isbn: trimmedIsbn.isEmpty ? nil : trimmedIsbn,
                coverImage: newCoverBase64
            )
            success = await store.updateBook(book, with: payload)
        }

        if !success {
            errorMessage = store.errorMessage ?? "Could not save this book."
        }
        return success
    }
}
