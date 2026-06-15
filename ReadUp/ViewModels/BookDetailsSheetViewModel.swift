import Foundation

@MainActor
@Observable
final class BookDetailsSheetViewModel {
    var isShowingStatusDialog = false
    var isShowingDeleteAlert = false
    var selectedStatus: BookStatus = .iWantToRead
    var isSaving = false
    var saveMessage: String?
    var alreadyExists = false
    var isShowingFullDescription = false

    /// Salva um livro vindo da busca na biblioteca do usuário (via backend).
    func saveBookToLibrary(source: BookDetailsSheet.Source, store: LibraryStore, onDismiss: @escaping () -> Void) async {
        guard case .search(let book, _) = source else { return }

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
