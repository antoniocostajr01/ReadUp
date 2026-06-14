import Foundation

enum AuthServiceError: LocalizedError {
    case invalidURL
    case serverError(message: String)
    case invalidResponse
    case networkUnavailable
    case unauthorized
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL."
        case .serverError(let message):
            return message
        case .invalidResponse:
            return "Invalid server response."
        case .networkUnavailable:
            return "Unable to reach the server. Check your connection."
        case .unauthorized:
            return "Your session expired. Please sign in again."
        case .notFound:
            return "Account not found."
        }
    }
}

// MARK: - Modelos de resposta

struct AuthUser: Codable, Identifiable {
    let id: String
    let name: String?
    let email: String
    var genres: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, email, genres
    }

    init(id: String, name: String?, email: String, genres: [String] = []) {
        self.id = id
        self.name = name
        self.email = email
        self.genres = genres
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        email = try c.decode(String.self, forKey: .email)
        // genres pode não vir em respostas antigas → default vazio.
        genres = try c.decodeIfPresent([String].self, forKey: .genres) ?? []
    }
}

struct AuthResponse: Codable {
    let user: AuthUser
    let token: String
}

/// Resposta de registro (POST /users) — não devolve token, só os dados do usuário.
private struct RegisterResponse: Codable {
    let id: String
    let name: String?
    let email: String
}

private struct BackendErrorResponse: Codable {
    let error: String?
}

/// Camada HTTP de autenticação. Segue o padrão de `BackendAIService`:
/// struct, métodos `async throws`, URL base vinda de `AppConfig.baseURL`.
struct AuthService {

    private var baseURL: String { AppConfig.baseURL }

    // MARK: - Registro

    func register(name: String, email: String, password: String) async throws -> AuthUser {
        let body: [String: Any] = ["name": name, "email": email, "password": password]
        let data = try await post(path: "/users", body: body)

        guard let registered = try? JSONDecoder().decode(RegisterResponse.self, from: data) else {
            throw AuthServiceError.invalidResponse
        }
        return AuthUser(id: registered.id, name: registered.name, email: registered.email)
    }

    // MARK: - Login email/senha

    func login(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = ["email": email, "password": password]
        let data = try await post(path: "/auth/login", body: body)
        return try decodeAuth(data)
    }

    // MARK: - Login com Apple

    func loginWithApple(identityToken: String, fullName: String?, email: String?) async throws -> AuthResponse {
        var body: [String: Any] = ["identityToken": identityToken]
        if let fullName, !fullName.isEmpty { body["fullName"] = fullName }
        if let email, !email.isEmpty { body["email"] = email }

        let data = try await post(path: "/auth/apple", body: body)
        return try decodeAuth(data)
    }

    // MARK: - Forgot / Reset password

    func forgotPassword(email: String) async throws {
        _ = try await post(path: "/auth/forgot-password", body: ["email": email])
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let body: [String: Any] = ["email": email, "code": code, "newPassword": newPassword]
        _ = try await post(path: "/auth/reset-password", body: body)
    }

    // MARK: - Perfil (requer token)

    /// Busca os dados do usuário logado (inclui os gêneros).
    func fetchMe(token: String) async throws -> AuthUser {
        let data = try await authedRequest(path: "/users/me", method: "GET", token: token, body: nil)
        guard let user = try? JSONDecoder().decode(AuthUser.self, from: data) else {
            throw AuthServiceError.invalidResponse
        }
        return user
    }

    /// Atualiza os gêneros do usuário e retorna a lista salva.
    func updateGenres(_ genres: [String], token: String) async throws -> [String] {
        let data = try await authedRequest(
            path: "/users/me/genres", method: "PUT", token: token, body: ["genres": genres]
        )
        struct GenresResponse: Codable { let genres: [String] }
        guard let decoded = try? JSONDecoder().decode(GenresResponse.self, from: data) else {
            throw AuthServiceError.invalidResponse
        }
        return decoded.genres
    }

    // MARK: - Helpers

    private func authedRequest(path: String, method: String, token: String, body: [String: Any]?) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw AuthServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthServiceError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AuthServiceError.unauthorized
        }

        // 404 em /users/me = o usuário do token não existe mais (ex.: deletado).
        if httpResponse.statusCode == 404 {
            throw AuthServiceError.notFound
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(BackendErrorResponse.self, from: data))?.error
                ?? "Something went wrong. Please try again."
            throw AuthServiceError.serverError(message: message)
        }

        return data
    }

    private func post(path: String, body: [String: Any]) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw AuthServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthServiceError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Tenta extrair a mensagem de erro do backend ({ "error": "..." }).
            let message = (try? JSONDecoder().decode(BackendErrorResponse.self, from: data))?.error
                ?? "Something went wrong. Please try again."
            throw AuthServiceError.serverError(message: message)
        }

        return data
    }

    private func decodeAuth(_ data: Data) throws -> AuthResponse {
        guard let auth = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
            throw AuthServiceError.invalidResponse
        }
        return auth
    }
}
