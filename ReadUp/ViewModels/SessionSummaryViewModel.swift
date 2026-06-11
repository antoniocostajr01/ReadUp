import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class SessionSummaryViewModel {
    var readingTime: Int
    var currentBook: Book
    var pagesRead: Int
    var previousProgress: Int
    var thoughts: String = ""
    var sessionToEdit: LiterarySession?

    init(readingTime: Int, currentBook: Book, pagesRead: Int, previousProgress: Int, sessionToEdit: LiterarySession? = nil) {
        self.readingTime = readingTime
        self.currentBook = currentBook
        self.pagesRead = pagesRead
        self.previousProgress = previousProgress
        self.sessionToEdit = sessionToEdit
    }

    /// Páginas lidas NESTA sessão
    var sessionPagesRead: Int {
        max(0, pagesRead - previousProgress)
    }

    /// Progresso total do livro (ex: 400/800 = 50%)
    var completionPercentage: Int {
        guard currentBook.numberOfPages > 0 else { return 0 }
        let progress = Double(min(pagesRead, currentBook.numberOfPages))
        return Int(((progress / Double(currentBook.numberOfPages)) * 100).rounded())
    }

    var sessionMinutes: Int {
        max(1, readingTime / 60)
    }

    func setupForEditting() {
        if let session = sessionToEdit {
            pagesRead = session.pagesRead
            currentBook = session.book
            thoughts = session.thoughts
            readingTime = session.timeRead
        }
    }

    func saveSession(modelContext: ModelContext, onSessionSaved: (() -> Void)?, onDismiss: @escaping () -> Void) {
        let session = LiterarySession(book: currentBook, pagesRead: sessionPagesRead, progress: pagesRead, timeRead: readingTime, thoughts: thoughts)
        modelContext.insert(session)

        // Auto-complete: se o progresso atingiu 100%, marca como lido
        if pagesRead >= currentBook.numberOfPages {
            currentBook.status = .read
        }

        do {
            try modelContext.save()
            onSessionSaved?()
            onDismiss()
        } catch {
            print("Failed to save session")
        }
    }
}
