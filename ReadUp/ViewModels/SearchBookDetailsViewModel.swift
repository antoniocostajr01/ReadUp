import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class SearchBookDetailsViewModel {
    var selectedStatus: BookStatus = .iWantToRead
    var isSaving = false
    var saveMessage: String?
    var alreadyExists = false
    var isShowingFullDescription = false
    
    func saveBookToLibrary(book: SearchBook, service: GoogleBooksService, modelContext: ModelContext, onDismiss: @escaping () -> Void) async {
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
