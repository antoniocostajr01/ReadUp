import Foundation

enum BackendAIServiceError: LocalizedError {
    case invalidURL
    case serverError(statusCode: Int)
    case emptyResponse
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL."
        case .serverError(let statusCode):
            return "Server returned status \(statusCode)."
        case .emptyResponse:
            return "The AI returned an empty response."
        case .networkUnavailable:
            return "Unable to reach the server. Check your connection."
        }
    }
}

struct BackendAIService {

    // Em dev local, use o IP do Mac na rede (ex: "http://192.168.0.10:3000")
    // No Simulator, "http://localhost:3000" funciona.
    // Em produção, troque pela URL do servidor deployado.
    private let baseURL = "http://localhost:3000"

    /// Envia o histórico completo da conversa para o backend e retorna a resposta.
    func chat(messages: [AIChatMessage]) async throws -> String {
        guard let url = URL(string: "\(baseURL)/ai/chat") else {
            throw BackendAIServiceError.invalidURL
        }

        // Converte AIChatMessage para o formato do backend
        let payload = messages.map { msg in
            [
                "role": msg.role == .user ? "user" : "assistant",
                "content": msg.text
            ]
        }

        let body = try JSONSerialization.data(withJSONObject: ["messages": payload])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw BackendAIServiceError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw BackendAIServiceError.serverError(statusCode: statusCode)
        }

        let decoded = try JSONDecoder().decode(BackendAIChatResponse.self, from: data)

        guard !decoded.reply.isEmpty else {
            throw BackendAIServiceError.emptyResponse
        }

        return decoded.reply
    }
}

// MARK: - Response Model
private struct BackendAIChatResponse: Decodable {
    let reply: String
}
