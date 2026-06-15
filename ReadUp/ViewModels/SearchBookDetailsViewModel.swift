import Foundation

@MainActor
@Observable
final class SearchBookDetailsViewModel {
    var selectedStatus: BookStatus = .iWantToRead
    var isSaving = false
    var saveMessage: String?
    var alreadyExists = false
    var isShowingFullDescription = false

    /// Salva um livro vindo da busca na biblioteca do usuário (via backend).
    func saveBookToLibrary(book: SearchBook, store: LibraryStore, onDismiss: @escaping () -> Void) async {
        isSaving = true
        defer { isSaving = false }

        let success = await store.addBook(from: book, status: selectedStatus)
        if success {
            saveMessage = "Book added successfully."
            alreadyExists = true
            onDismiss()
        } else {
            saveMessage = store.errorMessage ?? "Could not save this book."
        }
    }
}
