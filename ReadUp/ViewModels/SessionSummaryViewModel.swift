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

    /// Indica se o usuário está editando os pensamentos de uma sessão já salva.
    var isEditing = false

    /// `true` quando a tela está em modo de visualização de sessão anterior.
    var isReviewing: Bool { sessionToEdit != nil }

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

    /// Confirmação da última gravação, para a tela mostrar o retorno.
    ///
    /// Existe porque salvar era indistinguível de não salvar: no sucesso a tela se
    /// fechava sozinha, então o usuário via a mesma coisa que veria se o PUT tivesse
    /// falhado em silêncio. Agora a tela fica de pé, confirma, e o botão volta a Edit.
    var didSaveChanges = false

    /// Verdadeiro quando a última tentativa de gravar falhou. A `LibraryStore` guarda
    /// a mensagem; aqui só interessa que houve falha, para não mentir um sucesso.
    var didFailToSave = false

    /// Atualiza apenas os pensamentos de uma sessão existente.
    func updateSession(store: LibraryStore) async {
        guard let session = sessionToEdit else { return }
        isSaving = true
        defer { isSaving = false }

        didSaveChanges = false
        didFailToSave = false

        guard await store.updateSession(id: session.id, thoughts: thoughts) else {
            didFailToSave = true
            return
        }

        // Mantém o snapshot local coerente: `setupForEditting` relê daqui, e sem isto
        // um segundo Edit na mesma tela recarregaria o texto antigo.
        sessionToEdit?.thoughts = thoughts
        isEditing = false
        didSaveChanges = true
    }
}
