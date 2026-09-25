import Foundation

extension Notification.Name {
    /// O refresh token foi recusado: a sessão acabou de verdade e o app deve deslogar.
    static let readUpSessionExpired = Notification.Name("readUpSessionExpired")
}

/// Par de tokens devolvido por `/auth/refresh` e `/auth/session`.
struct TokenPair: Decodable {
    let token: String
    let refreshToken: String
}

/// Renova o access token com o refresh token guardado no Keychain.
///
/// Um `actor` com uma única renovação em voo: a Home dispara livros e sessões ao mesmo
/// tempo, e dois 401 simultâneos não podem gastar o mesmo refresh duas vezes — o segundo
/// espera o primeiro e reaproveita o token novo.
actor TokenRefresher {
    static let shared = TokenRefresher()

    private var inFlight: Task<String, Error>?

    /// Devolve um access token válido para substituir `rejected`.
    ///
    /// Lança `BackendError.unauthorized` só quando o servidor recusa o refresh (e aí
    /// avisa o app para deslogar). Falha de rede ou de servidor é outro erro: o usuário
    /// continua logado e a próxima chamada tenta de novo.
    func refresh(rejected: String) async throws -> String {
        // Outra chamada já renovou enquanto esta esperava a resposta do 401.
        if let current = KeychainHelper.read(KeychainKey.authToken), current != rejected {
            return current
        }
        if let inFlight {
            return try await inFlight.value
        }

        let task = Task { try await Self.performRefresh() }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }

    private static func performRefresh() async throws -> String {
        guard let refreshToken = KeychainHelper.read(KeychainKey.refreshToken) else {
            await expireSession()
            throw BackendError.unauthorized
        }

        guard let url = URL(string: "\(AppConfig.baseURL)/auth/refresh") else {
            throw BackendError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refreshToken": refreshToken])

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw BackendError.networkUnavailable
        }

        guard let http = response as? HTTPURLResponse else { throw BackendError.invalidResponse }
        if http.statusCode == 401 {
            await expireSession()
            throw BackendError.unauthorized
        }
        guard (200...299).contains(http.statusCode),
              let pair = try? JSONDecoder().decode(TokenPair.self, from: data) else {
            throw BackendError.serverError(message: "Something went wrong. Please try again.")
        }

        KeychainHelper.save(pair.token, for: KeychainKey.authToken)
        KeychainHelper.save(pair.refreshToken, for: KeychainKey.refreshToken)
        return pair.token
    }

    @MainActor
    private static func expireSession() {
        NotificationCenter.default.post(name: .readUpSessionExpired, object: nil)
    }
}
