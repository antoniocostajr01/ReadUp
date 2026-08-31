import Foundation

@MainActor
@Observable
final class BookDetailsViewModel {
    var isShowingStatusDialog = false
    var isShowingDeleteAlert = false
    var selectedStatus: BookStatus = .iWantToRead
    var isSaving = false
    var saveMessage: String?
    var alreadyExists = false
    var isShowingFullDescription = false

    /// Salva um livro vindo da busca na biblioteca do usuário (via backend).
    /// Devolve o livro criado — é ele que a tela de conquista exibe.
    func saveBookToLibrary(source: BookDetailsView.Source, store: LibraryStore) async -> Book? {
        guard case .search(let book, _) = source else { return nil }

        isSaving = true
        defer { isSaving = false }

        guard let created = await store.addBook(from: book, status: selectedStatus) else {
            saveMessage = store.errorMessage ?? Localization.BookDetails.saveError.string
            return nil
        }
        alreadyExists = true
        return created
    }
}
