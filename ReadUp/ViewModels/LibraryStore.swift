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
        errorMessage = nil
        isLoading = false
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
