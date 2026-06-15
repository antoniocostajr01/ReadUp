import Foundation

/// Payload para criar um livro (POST /books).
struct CreateBookPayload: Encodable {
    let title: String
    let author: String?
    let totalPages: Int
    let details: String?
    let coverUrl: String?
    let status: String
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
}

/// Chamadas HTTP de livros. Segue o padrão de `AuthService`, usando `BackendClient`.
struct BookService {
    private let client = BackendClient.shared

    func fetchBooks(token: String) async throws -> [Book] {
        let data = try await client.send(path: "/books", method: "GET", token: token)
        return try BackendClient.decoder.decode([Book].self, from: data)
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
