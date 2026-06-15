import Foundation

/// Resposta de sessão do backend (GET/POST /sessions). Traz `bookId`; o livro é resolvido no `LibraryStore`.
struct ReadingSessionDTO: Codable {
    let id: String
    let userId: String
    let bookId: String
    let pagesRead: Int
    let thoughts: String?
    let readingTimeSeconds: Int
    let date: Date
}

/// Payload para criar uma sessão (POST /sessions).
struct CreateSessionPayload: Encodable {
    let bookId: String
    let pagesRead: Int
    let thoughts: String?
    let readingTimeSeconds: Int
}

/// Chamadas HTTP de sessões de leitura.
struct ReadingSessionService {
    private let client = BackendClient.shared

    func fetchSessions(token: String) async throws -> [ReadingSessionDTO] {
        let data = try await client.send(path: "/sessions", method: "GET", token: token)
        return try BackendClient.decoder.decode([ReadingSessionDTO].self, from: data)
    }

    func createSession(_ payload: CreateSessionPayload, token: String) async throws -> ReadingSessionDTO {
        let body = try JSONEncoder().encode(payload)
        let data = try await client.send(path: "/sessions", method: "POST", token: token, body: body)
        return try BackendClient.decoder.decode(ReadingSessionDTO.self, from: data)
    }

    func deleteSession(id: String, token: String) async throws {
        _ = try await client.send(path: "/sessions/\(id)", method: "DELETE", token: token)
    }
}
