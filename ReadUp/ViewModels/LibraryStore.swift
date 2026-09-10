import Foundation
import Network

/// Fonte de verdade (em memória) dos livros e sessões do usuário logado.
/// Carrega do backend no login e é zerada no logout — garantindo isolamento por usuário.
@MainActor
@Observable
final class LibraryStore {
    var books: [Book] = []
    var sessions: [LiterarySession] = []
    var isLoading = false
    var errorMessage: String?

    private let bookService = BookService()
    private let sessionService = ReadingSessionService()
    private let pathMonitor = NWPathMonitor()

    private var token: String? {
        KeychainHelper.read(KeychainKey.authToken)
    }

    init() {
        // Uma tentativa no boot, e depois sempre que a rede voltar — a fila de
        // sessões pendentes existe pra sobreviver justamente a esses dois momentos.
        Task { await PendingSessionStore.shared.flush(store: self) }
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied, let self else { return }
            Task { @MainActor in
                await PendingSessionStore.shared.flush(store: self)
            }
        }
        pathMonitor.start(queue: DispatchQueue(label: "com.readup.libraryStore.pathMonitor"))
    }

    // MARK: - Ciclo de vida da sessão

    /// Carrega livros e sessões do usuário logado.
    func load() async {
        guard let token else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetchedBooks = try await bookService.fetchBooks(token: token)
            let dtos = try await sessionService.fetchSessions(token: token)
            books = fetchedBooks
            sessions = assemble(dtos, books: fetchedBooks)
            warmCovers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deixa as capas da biblioteca baixadas antes de a grade aparecer.
    /// Fora do `await` de propósito: uma capa lenta não deve segurar a tela de carga.
    private func warmCovers() {
        let urls = books.compactMap { $0.coverUrl.flatMap(URL.init(string:)) }
        Task { await CoverImageCache.warm(urls) }
    }

    /// Limpa todos os dados em memória (chamado no logout).
    func reset() {
        books = []
        sessions = []
        CoverImageCache.clear()
        errorMessage = nil
        isLoading = false
    }

    // MARK: - Livros

    /// Adiciona um livro vindo da busca (Google Books) à biblioteca do usuário.
    @discardableResult
    func addBook(from searchBook: SearchBook, status: BookStatus, isbn: String? = nil) async -> Book? {
        guard let token else { return nil }
        let payload = CreateBookPayload(
            title: searchBook.title,
            author: searchBook.author,
            totalPages: searchBook.numberOfPages,
            details: searchBook.details,
            coverUrl: searchBook.thumbnailURL?.absoluteString,
            status: status.rawValue,
            isbn: isbn
        )
        do {
            let book = try await bookService.createBook(payload, token: token)
            books.append(book)
            return book
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Cria um livro cadastrado manualmente (sem passar pela busca).
    @discardableResult
    func createManualBook(_ payload: CreateBookPayload) async -> Book? {
        guard let token else { return nil }
        do {
            let book = try await bookService.createBook(payload, token: token)
            books.append(book)
            return book
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Atualiza os campos editáveis de um livro existente (formulário de edição).
    @discardableResult
    func updateBook(_ book: Book, with payload: UpdateBookPayload) async -> Bool {
        guard let token else { return false }
        do {
            let updated = try await bookService.updateBook(id: book.id, payload, token: token)
            if let index = books.firstIndex(where: { $0.id == updated.id }) {
                books[index] = updated
            }
            if let coverUrl = updated.coverUrl.flatMap(URL.init(string:)) {
                CoverImageCache.invalidate(coverUrl)
            }
            for i in sessions.indices where sessions[i].book.id == updated.id {
                sessions[i].book = updated
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateStatus(_ book: Book, to status: BookStatus) async {
        await applyUpdate(bookId: book.id, payload: UpdateBookPayload(status: status.rawValue))
    }

    func deleteBook(_ book: Book) async {
        guard let token else { return }
        do {
            try await bookService.deleteBook(id: book.id, token: token)
            books.removeAll { $0.id == book.id }
            sessions.removeAll { $0.book.id == book.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// `true` se o usuário já tem um livro com mesmo título/autor (evita duplicar).
    func contains(_ searchBook: SearchBook) -> Bool {
        books.contains {
            $0.title.caseInsensitiveCompare(searchBook.title) == .orderedSame &&
            $0.author.caseInsensitiveCompare(searchBook.author) == .orderedSame
        }
    }

    // MARK: - Sessões

    /// Registra uma sessão de leitura e atualiza o progresso/status do livro no backend.
    /// - Parameters:
    ///   - sessionPagesRead: páginas lidas NESTA sessão.
    ///   - totalProgress: página total atingida (novo progresso do livro).
    ///   - timeRead: duração em segundos.
    /// O usuário nunca fica travado: se o POST falhar (ex.: sem rede), a sessão
    /// é guardada localmente (`PendingSessionStore`) e uma sessão "pending:" é
    /// devolvida do mesmo jeito, pra UI seguir em frente.
    @discardableResult
    func logSession(book: Book, sessionPagesRead: Int, totalProgress: Int, timeRead: Int, thoughts: String) async -> LiterarySession? {
        guard let token else { return nil }
        do {
            let sessionPayload = CreateSessionPayload(
                bookId: book.id,
                pagesRead: sessionPagesRead,
                thoughts: thoughts.isEmpty ? nil : thoughts,
                readingTimeSeconds: timeRead
            )
            let dto = try await sessionService.createSession(sessionPayload, token: token)

            // Atualiza progresso e, se concluiu, marca como lido.
            let completed = totalProgress >= book.numberOfPages
            let updatePayload = UpdateBookPayload(
                status: completed ? BookStatus.read.rawValue : nil,
                progress: totalProgress
            )
            let updatedBook = try await bookService.updateBook(id: book.id, updatePayload, token: token)
            if let index = books.firstIndex(where: { $0.id == updatedBook.id }) {
                books[index] = updatedBook
            }

            let session = LiterarySession(
                id: dto.id,
                book: updatedBook,
                pagesRead: dto.pagesRead,
                timeRead: dto.readingTimeSeconds,
                thoughts: dto.thoughts ?? "",
                timesTamp: dto.date
            )
            sessions.insert(session, at: 0)
            return session
        } catch {
            errorMessage = error.localizedDescription

            // Sem rede (ou outra falha): não perde a sessão, guarda na fila local
            // e aplica o progresso no livro localmente enquanto isso.
            let localID = "pending:\(UUID().uuidString)"
            let pending = PendingSession(
                localID: localID,
                bookID: book.id,
                pagesRead: sessionPagesRead,
                totalProgress: totalProgress,
                readingTimeSeconds: timeRead,
                thoughts: thoughts,
                date: Date()
            )
            PendingSessionStore.shared.enqueue(pending)

            let completed = totalProgress >= book.numberOfPages
            var localBook = book
            localBook.progress = totalProgress
            if completed { localBook.status = .read }
            if let index = books.firstIndex(where: { $0.id == book.id }) {
                books[index] = localBook
            }

            let session = LiterarySession(
                id: localID,
                book: localBook,
                pagesRead: sessionPagesRead,
                timeRead: timeRead,
                thoughts: thoughts,
                timesTamp: pending.date
            )
            sessions.insert(session, at: 0)
            return session
        }
    }

    /// Progresso do livro **no momento daquela sessão**, acumulado.
    ///
    /// A `ReadingSession` guarda só o delta (páginas lidas naquela sessão), então uma
    /// sessão antiga aberta pelo histórico não sabe sozinha em que página o livro
    /// estava. Sem isto, cada sessão mostrava o próprio delta como se fosse o total —
    /// ler 10 páginas e depois 11 aparecia como 10/300 e 11/300, em vez de 10/300 e
    /// 21/300.
    ///
    /// ponytail: soma os deltas das sessões anteriores do mesmo livro. Diverge se o
    /// progresso for editado à mão no formulário do livro; guardar o total na própria
    /// sessão exigiria uma coluna nova e uma migration no Supabase de produção.
    func cumulativeProgress(upTo session: LiterarySession) -> (previous: Int, total: Int) {
        let previous = sessions
            .filter { $0.book.id == session.book.id && $0.timesTamp < session.timesTamp }
            .reduce(0) { $0 + $1.pagesRead }
        return (previous, previous + session.pagesRead)
    }

    /// Atualiza os pensamentos de uma sessão existente. Sessões ainda pendentes
    /// (id "pending:") não existem no backend — a edição fica só na fila local.
    @discardableResult
    func updateSession(id: String, thoughts: String) async -> Bool {
        if id.hasPrefix("pending:") {
            PendingSessionStore.shared.updateThoughts(localID: id, thoughts)
            if let index = sessions.firstIndex(where: { $0.id == id }) {
                sessions[index].thoughts = thoughts
            }
            return true
        }
        guard let token else { return false }
        do {
            let payload = UpdateSessionPayload(thoughts: thoughts.isEmpty ? nil : thoughts)
            let dto = try await sessionService.updateSession(id: id, payload, token: token)
            if let index = sessions.firstIndex(where: { $0.id == id }) {
                sessions[index].thoughts = dto.thoughts ?? ""
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Helpers

    private func applyUpdate(bookId: String, payload: UpdateBookPayload) async {
        guard let token else { return }
        do {
            let updated = try await bookService.updateBook(id: bookId, payload, token: token)
            if let index = books.firstIndex(where: { $0.id == updated.id }) {
                books[index] = updated
            }
            // Mantém o snapshot do livro nas sessões coerente.
            for i in sessions.indices where sessions[i].book.id == updated.id {
                sessions[i].book = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Ordena da mais recente para a mais antiga aqui, e não em cada tela: o backend
    /// devolve `GET /sessions` sem ordem garantida, e tanto o `prefix(4)` do Home quanto
    /// as seções do History assumem "mais nova primeiro". Ordenando na montagem, o
    /// `sessions.insert(_, at: 0)` do `logSession` continua correto.
    private func assemble(_ dtos: [ReadingSessionDTO], books: [Book]) -> [LiterarySession] {
        let booksById = Dictionary(books.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return dtos.compactMap { dto in
            guard let book = booksById[dto.bookId] else { return nil }
            return LiterarySession(
                id: dto.id,
                book: book,
                pagesRead: dto.pagesRead,
                timeRead: dto.readingTimeSeconds,
                thoughts: dto.thoughts ?? "",
                timesTamp: dto.date
            )
        }
        .sorted { $0.timesTamp > $1.timesTamp }
    }
}
