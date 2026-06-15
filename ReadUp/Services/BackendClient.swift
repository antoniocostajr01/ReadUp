import Foundation

/// Erros padronizados das chamadas autenticadas ao backend.
enum BackendError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkUnavailable
    case unauthorized
    case forbidden
    case notFound
    case serverError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid backend URL."
        case .invalidResponse: return "Invalid server response."
        case .networkUnavailable: return "Unable to reach the server. Check your connection."
        case .unauthorized: return "Your session expired. Please sign in again."
        case .forbidden: return "You don't have access to this resource."
        case .notFound: return "Resource not found."
        case .serverError(let message): return message
        }
    }
}

private struct BackendErrorResponse: Decodable {
    let error: String?
}

/// Camada HTTP compartilhada por `BookService`/`ReadingSessionService`.
/// Segue o mesmo padrão de `AuthService` (token Bearer, base de `AppConfig`),
/// mas trabalha com `Data` no corpo para os services encodarem seus próprios DTOs.
struct BackendClient {
    static let shared = BackendClient()

    private var baseURL: String { AppConfig.baseURL }

    /// Decoder configurado para as datas ISO8601 (com ou sem frações de segundo) que o backend devolve.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = withFraction.date(from: string) ?? plain.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return decoder
    }()

    func send(path: String, method: String, token: String, body: Data? = nil) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw BackendError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw BackendError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw BackendError.unauthorized
        case 403:
            throw BackendError.forbidden
        case 404:
            throw BackendError.notFound
        default:
            let message = (try? JSONDecoder().decode(BackendErrorResponse.self, from: data))?.error
                ?? "Something went wrong. Please try again."
            throw BackendError.serverError(message: message)
        }
    }
}
