import Foundation

/// Fonte de verdade (em memória) dos livros e sessões do usuário logado.
/// Carrega do backend no login e é zerada no logout — garantindo isolamento por usuário.
@MainActor
@Observable
final class LibraryStore {
    var books: [Book] = []
    var sessions: [LiterarySession] = []
    var isLoading = false
    var errorMessage: String?

    /// Cache em memória das capas já baixadas (chave = `coverUrl`).
    /// O `AsyncImage` recarrega ao reciclar células e falha sob carga; este cache garante
    /// que as capas da Home (livros `reading`) fiquem estáveis depois de baixadas uma vez.
    var coverCache: [String: Data] = [:]

    private let bookService = BookService()
    private let sessionService = ReadingSessionService()

    private var token: String? {
        KeychainHelper.read(KeychainKey.authToken)
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Limpa todos os dados em memória (chamado no logout).
    func reset() {
        books = []
        sessions = []
        coverCache = [:]
        errorMessage = nil
        isLoading = false
    }

    // MARK: - Capas (Home)

    /// Verifica o estado das capas dos livros `reading` e baixa (GET) só as que ainda
    /// não estão no cache. Chamado quando a Home aparece, para garantir que as capas
    /// sejam exibidas mesmo que o `AsyncImage` tenha falhado ou os dados sejam recentes.
    func ensureReadingCovers() async {
        let urls = books
            .filter { $0.status == .reading }
            .compactMap { $0.coverUrl }
            .filter { !$0.isEmpty }

        let missing = Array(Set(urls.filter { coverCache[$0] == nil }))
        guard !missing.isEmpty else { return }

        let downloaded = await withTaskGroup(of: (String, Data?).self) { group -> [(String, Data)] in
            for urlString in missing {
                group.addTask { (urlString, await Self.downloadImage(from: urlString)) }
            }
            var result: [(String, Data)] = []
            for await (urlString, data) in group {
                if let data { result.append((urlString, data)) }
            }
            return result
        }

        for (urlString, data) in downloaded {
            coverCache[urlString] = data
        }
    }

    /// Baixa os bytes de uma imagem, validando que a resposta é 2xx.
    private static func downloadImage(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            return data
        } catch {
            return nil
        }
    }

    // MARK: - Livros

    /// Adiciona um livro vindo da busca (Google Books) à biblioteca do usuário.
    @discardableResult
    func addBook(from searchBook: SearchBook, status: BookStatus) async -> Bool {
        guard let token else { return false }
        let payload = CreateBookPayload(
            title: searchBook.title,
            author: searchBook.author,
            totalPages: searchBook.numberOfPages,
            details: searchBook.details,
            coverUrl: searchBook.thumbnailURL?.absoluteString,
            status: status.rawValue
        )
        do {
            let book = try await bookService.createBook(payload, token: token)
            books.append(book)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Cria um livro cadastrado manualmente (sem passar pela busca).
    @discardableResult
    func createManualBook(_ payload: CreateBookPayload) async -> Bool {
        guard let token else { return false }
        do {
            let book = try await bookService.createBook(payload, token: token)
            books.append(book)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
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
            if let coverUrl = updated.coverUrl {
                coverCache[coverUrl] = nil
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
    @discardableResult
    func logSession(book: Book, sessionPagesRead: Int, totalProgress: Int, timeRead: Int, thoughts: String) async -> Bool {
        guard let token else { return false }
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
    }
}
