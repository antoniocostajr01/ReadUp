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

    // MARK: Grade da Library (paginada)
    //
    // `books` continua sendo a estante inteira — só metadados, sem capa, então é leve —
    // porque a Home, o Perfil, as sessões e a checagem de duplicados precisam dela
    // toda. A grade é outra coisa: vem do backend de 10 em 10, já filtrada e ordenada,
    // para que as capas carreguem aos poucos em vez de todas no boot.

    /// O que a grade está mostrando: filtro de status e busca por título/autor.
    struct GridQuery: Equatable {
        var status: BookStatus?
        var text = ""
    }

    static let gridPageSize = 10

    private(set) var gridItems: [Book] = []
    private(set) var gridHasMore = false
    private(set) var isLoadingGridPage = false
    /// `false` até a primeira página da consulta atual chegar — evita piscar "nenhum
    /// resultado" enquanto ela ainda está a caminho.
    private(set) var hasLoadedGrid = false
    private(set) var counts = BookCounts()
    private var gridQuery = GridQuery()
    /// Muda a cada recomeço da grade: uma página antiga que chega atrasada é descartada.
    private var gridGeneration = 0

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
        async let grid: () = refreshGrid()
        do {
            let fetchedBooks = try await bookService.fetchBooks(token: token)
            let dtos = try await sessionService.fetchSessions(token: token)
            books = fetchedBooks
            sessions = assemble(dtos, books: fetchedBooks)
            warmCovers()
        } catch {
            errorMessage = error.localizedDescription
        }
        await grid
    }

    /// Deixa baixadas as capas que a Home mostra logo de cara (os livros em leitura).
    /// As da grade chegam com as páginas. Fora do `await` de propósito: uma capa lenta
    /// não deve segurar a tela de carga.
    private func warmCovers() {
        let urls = books
            .filter { $0.status == .reading || $0.status == .rereading }
            .compactMap { $0.coverUrl.flatMap(URL.init(string:)) }
        Task { await CoverImageCache.warm(urls) }
    }

    // MARK: - Grade paginada

    /// Troca o filtro/busca da grade. Mesma consulta já carregada = nada a fazer.
    func setGridQuery(_ query: GridQuery) async {
        guard query != gridQuery || !hasLoadedGrid else { return }
        gridQuery = query
        await refreshGrid()
    }

    /// Recomeça a grade da primeira página e recarrega os contadores dos chips.
    func refreshGrid() async {
        async let page: () = loadGridPage(reset: true)
        async let counts: () = loadCounts()
        _ = await (page, counts)
    }

    /// Próxima página (ou a primeira, com `reset`).
    func loadGridPage(reset: Bool) async {
        guard let token else { return }
        if reset {
            gridGeneration += 1
            hasLoadedGrid = false
        } else {
            guard gridHasMore, !isLoadingGridPage, hasLoadedGrid else { return }
        }
        let generation = gridGeneration
        let query = gridQuery
        isLoadingGridPage = true
        defer { if generation == gridGeneration { isLoadingGridPage = false } }

        do {
            let page = try await bookService.fetchBooksPage(
                limit: Self.gridPageSize,
                offset: reset ? 0 : gridItems.count,
                status: query.status,
                query: query.text.trimmingCharacters(in: .whitespaces),
                token: token
            )
            guard generation == gridGeneration else { return }
            if reset {
                gridItems = page.items
            } else {
                // Um livro criado ou apagado entre duas páginas desloca o offset:
                // sem isto, o mesmo livro podia aparecer duas vezes na grade.
                let known = Set(gridItems.map(\.id))
                gridItems += page.items.filter { !known.contains($0.id) }
            }
            gridHasMore = page.hasMore
            hasLoadedGrid = true
        } catch {
            guard generation == gridGeneration else { return }
            errorMessage = error.localizedDescription
            // Sem isto a grade ficaria para sempre em "carregando".
            hasLoadedGrid = true
        }
    }

    private func loadCounts() async {
        guard let token else { return }
        let text = gridQuery.text.trimmingCharacters(in: .whitespaces)
        if let fetched = try? await bookService.fetchCounts(query: text, token: token),
           text == gridQuery.text.trimmingCharacters(in: .whitespaces) {
            counts = fetched
        }
    }

    /// Reflete na grade um livro que mudou. Se ele saiu do filtro atual (ex.: mudou de
    /// status com o chip "Lendo" ativo), sai da grade.
    private func syncGrid(_ book: Book, statusChanged: Bool) {
        if let index = gridItems.firstIndex(where: { $0.id == book.id }) {
            if let status = gridQuery.status, book.status != status {
                gridItems.remove(at: index)
            } else {
                gridItems[index] = book
            }
        }
        if statusChanged {
            Task { await loadCounts() }
        }
    }

    /// Ponto único para gravar um livro atualizado: estante, snapshot nas sessões e grade.
    /// O `PendingSessionStore` também passa por aqui ao sincronizar a fila offline.
    func apply(updated book: Book) {
        let previousStatus = books.first(where: { $0.id == book.id })?.status
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
        }
        for i in sessions.indices where sessions[i].book.id == book.id {
            sessions[i].book = book
        }
        syncGrid(book, statusChanged: previousStatus != book.status)
    }

    /// Limpa todos os dados em memória (chamado no logout).
    func reset() {
        books = []
        sessions = []
        gridItems = []
        gridHasMore = false
        hasLoadedGrid = false
        counts = BookCounts()
        gridQuery = GridQuery()
        gridGeneration += 1
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
            // O livro novo entra na ordem alfabética, que só o backend conhece por página.
            Task { await refreshGrid() }
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
            Task { await refreshGrid() }
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
            if let coverUrl = updated.coverUrl.flatMap(URL.init(string:)) {
                CoverImageCache.invalidate(coverUrl)
            }
            apply(updated: updated)
            // Um título editado muda a posição do livro na ordem alfabética da grade.
            if updated.title != book.title {
                Task { await refreshGrid() }
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
            gridItems.removeAll { $0.id == book.id }
            await loadCounts()
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

            // Atualiza progresso e o status: concluiu → lido; era "quero ler" → lendo.
            let completed = totalProgress >= book.numberOfPages
            let updatePayload = UpdateBookPayload(
                status: BookStatus.afterSession(from: book.status, completed: completed)?.rawValue,
                progress: totalProgress
            )
            let updatedBook = try await bookService.updateBook(id: book.id, updatePayload, token: token)
            apply(updated: updatedBook)

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
            if let status = BookStatus.afterSession(from: book.status, completed: completed) {
                localBook.status = status
            }
            apply(updated: localBook)

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
            apply(updated: updated)
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
