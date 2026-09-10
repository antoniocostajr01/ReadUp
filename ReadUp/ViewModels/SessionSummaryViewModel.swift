import Foundation

@MainActor
@Observable
final class SessionSummaryViewModel {
    /// De onde a tela foi alcançada. A sessão já está salva nos dois casos — o que
    /// muda é só o que os botões fazem e dizem.
    enum Mode {
        /// Acabou de terminar de ler: `ReadingSession` já gravou a sessão.
        case finished
        /// Revendo uma sessão antiga, vinda de Home ou History.
        case reviewing
    }

    var readingTime: Int
    var currentBook: Book
    var pagesRead: Int
    var previousProgress: Int
    var thoughts: String = ""
    var session: LiterarySession
    let mode: Mode
    var isSaving = false

    /// Indica se o usuário está editando os pensamentos de uma sessão já salva.
    var isEditing = false

    /// `true` quando a tela está em modo de visualização de sessão anterior.
    var isReviewing: Bool { mode == .reviewing }

    init(readingTime: Int, currentBook: Book, pagesRead: Int, previousProgress: Int, session: LiterarySession, mode: Mode) {
        self.readingTime = readingTime
        self.currentBook = currentBook
        self.pagesRead = pagesRead
        self.previousProgress = previousProgress
        self.session = session
        self.mode = mode
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
        guard mode == .reviewing else { return }
        // `pagesRead` NÃO é relido daqui: `session.pagesRead` é o delta da sessão, e
        // quem abriu a tela já passou o progresso acumulado do livro naquele momento
        // (`LibraryStore.cumulativeProgress(upTo:)`). Reler o delta aqui desfazia essa
        // conta — era o que fazia o card mostrar 15/384 e "6 páginas" numa sessão de
        // 15 páginas sobre um livro que estava na 24.
        currentBook = session.book
        thoughts = session.thoughts
        readingTime = session.timeRead
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
        session.thoughts = thoughts
        isEditing = false
        didSaveChanges = true
    }

    /// "Back to home": grava os pensamentos digitados, se houver algum, antes de sair.
    /// A sessão já existe — uma falha aqui perde só o texto, não a sessão — então não
    /// há toast nem bloqueio de saída, o usuário já está de saída.
    func finish(store: LibraryStore) async {
        guard !thoughts.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }
        await store.updateSession(id: session.id, thoughts: thoughts)
    }
}
