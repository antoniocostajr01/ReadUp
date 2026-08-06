import Foundation

@MainActor
@Observable
final class SessionSummaryViewModel {
    var readingTime: Int
    var currentBook: Book
    var pagesRead: Int
    var previousProgress: Int
    var thoughts: String = ""
    var sessionToEdit: LiterarySession?
    var isSaving = false
    private(set) var hasSaved = false

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

    /// Duração real da sessão formatada como hh:mm:ss.
    var sessionTimeFormatted: String {
        let hours = readingTime / 3600
        let minutes = (readingTime % 3600) / 60
        let seconds = readingTime % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    func setupForEditting() {
        if let session = sessionToEdit {
            pagesRead = session.pagesRead
            currentBook = session.book
            thoughts = session.thoughts
            readingTime = session.timeRead
        }
    }

    /// Registra a sessão no backend (via store) e atualiza o progresso do livro.
    func saveSession(store: LibraryStore, onSessionSaved: (() -> Void)?, onDismiss: @escaping () -> Void) async {
        // Idempotente: evita salvar duas vezes quando o botão Confirmar e a rede
        // de segurança do onDisappear disparam para a mesma sessão.
        guard !hasSaved else {
            onDismiss()
            return
        }
        isSaving = true
        defer { isSaving = false }

        let success = await store.logSession(
            book: currentBook,
            sessionPagesRead: sessionPagesRead,
            totalProgress: pagesRead,
            timeRead: readingTime,
            thoughts: thoughts
        )

        if success {
            hasSaved = true
            onSessionSaved?()
            onDismiss()
        }
    }
}
