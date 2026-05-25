import Foundation
import SwiftData
import SwiftUI

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
    
    func deleteLibraryBookIfNeeded(source: BookDetailsSheet.Source, modelContext: ModelContext, onDismiss: () -> Void) {
        guard case .library(let book) = source else { return }

        do {
            let bookIdToDelete = book.id
            let predicate = #Predicate<LiterarySession> { session in
                session.book.id == bookIdToDelete
            }
            let descriptor = FetchDescriptor<LiterarySession>(predicate: predicate)
            let sessionsToDelete = try modelContext.fetch(descriptor)

            for session in sessionsToDelete {
                modelContext.delete(session)
            }

            modelContext.delete(book)
            try modelContext.save()
            onDismiss()
        } catch {
            print("Falha ao deletar as sessões: \(error.localizedDescription)")
        }
    }

    func saveBookToLibrary(source: BookDetailsSheet.Source, modelContext: ModelContext, onDismiss: @escaping () -> Void) async {
        guard case .search(let book, let service) = source else { return }

        isSaving = true
        defer { isSaving = false }

        let imageData = await service.loadImageData(from: book.thumbnailURL) ?? Data()
        let newBook = Book(
            title: book.title,
            author: book.author,
            numberOfPages: book.numberOfPages,
            details: book.details,
            status: selectedStatus,
            imageData: imageData
        )

        modelContext.insert(newBook)

        do {
            try modelContext.save()
            saveMessage = "Book added successfully."
            alreadyExists = true
            onDismiss()
        } catch {
            saveMessage = "Could not save this book."
        }
    }
}
