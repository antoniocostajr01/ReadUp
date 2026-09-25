import Foundation

/// Payload para criar um livro (POST /books).
struct CreateBookPayload: Encodable {
    let title: String
    let author: String?
    let totalPages: Int
    let details: String?
    let coverUrl: String?
    let status: String
    var isbn: String? = nil
    var coverImage: String? = nil
}

/// Payload para atualizar um livro (PUT /books/:id).
/// Campos opcionais nil são omitidos do JSON (encodeIfPresent), então não sobrescrevem o backend.
struct UpdateBookPayload: Encodable {
    var title: String?
    var author: String?
    var totalPages: Int?
    var details: String?
    var coverUrl: String?
    var status: String?
    var progress: Int?
    var isbn: String?
    var coverImage: String?
}

/// Uma página da estante (`GET /books?limit=&offset=`).
struct BookPage: Decodable {
    let items: [Book]
    let total: Int
    let hasMore: Bool
}

/// Quantos livros há em cada status (`GET /books/counts`). Alimenta os chips da Library.
struct BookCounts: Decodable, Equatable {
    var all = 0
    var read = 0
    var reading = 0
    var iWantToRead = 0
    var abandoned = 0
    var rereading = 0

    enum CodingKeys: String, CodingKey {
        case all, read, reading, abandoned, rereading
        case iWantToRead = "i_want_to_read"
    }

    /// `nil` é "Todos".
    func count(for status: BookStatus?) -> Int {
        switch status {
        case nil: all
        case .read: read
        case .reading: reading
        case .iWantToRead: iWantToRead
        case .abandoned: abandoned
        case .rereading: rereading
        }
    }
}

/// Chamadas HTTP de livros. Segue o padrão de `AuthService`, usando `BackendClient`.
struct BookService {
    private let client = BackendClient.shared

    func fetchBooks(token: String) async throws -> [Book] {
        let data = try await client.send(path: "/books", method: "GET", token: token)
        return try BackendClient.decoder.decode([Book].self, from: data)
    }

    /// Uma página da estante, já filtrada e na ordem da grade (título).
    func fetchBooksPage(limit: Int, offset: Int, status: BookStatus?, query: String, token: String) async throws -> BookPage {
        var items = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        if let status { items.append(URLQueryItem(name: "status", value: status.rawValue)) }
        if !query.isEmpty { items.append(URLQueryItem(name: "q", value: query)) }
        let data = try await client.send(path: Self.path("/books", items), method: "GET", token: token)
        return try BackendClient.decoder.decode(BookPage.self, from: data)
    }

    func fetchCounts(query: String, token: String) async throws -> BookCounts {
        let items = query.isEmpty ? [] : [URLQueryItem(name: "q", value: query)]
        let data = try await client.send(path: Self.path("/books/counts", items), method: "GET", token: token)
        return try BackendClient.decoder.decode(BookCounts.self, from: data)
    }

    /// O `BackendClient` recebe só o path: a query string vai montada (e escapada) nele.
    private static func path(_ base: String, _ items: [URLQueryItem]) -> String {
        guard !items.isEmpty else { return base }
        var components = URLComponents()
        components.path = base
        components.queryItems = items
        return components.string ?? base
    }

    func createBook(_ payload: CreateBookPayload, token: String) async throws -> Book {
        let body = try JSONEncoder().encode(payload)
        let data = try await client.send(path: "/books", method: "POST", token: token, body: body)
        return try BackendClient.decoder.decode(Book.self, from: data)
    }

    func updateBook(id: String, _ payload: UpdateBookPayload, token: String) async throws -> Book {
        let body = try JSONEncoder().encode(payload)
        let data = try await client.send(path: "/books/\(id)", method: "PUT", token: token, body: body)
        return try BackendClient.decoder.decode(Book.self, from: data)
    }

    func deleteBook(id: String, token: String) async throws {
        _ = try await client.send(path: "/books/\(id)", method: "DELETE", token: token)
    }
}
