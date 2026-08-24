import Foundation

enum GoogleBooksServiceError: LocalizedError {
    case invalidURL
    case apiError(message: String)
    case invalidResponse
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .apiError(let message):
            return message
        case .invalidResponse:
            return "Invalid server response."
        case .networkUnavailable:
            return "Unable to reach the server. Check your connection."
        }
    }
}

private struct BackendErrorResponse: Decodable {
    let error: String?
}

/// Busca de livros via backend (`GET /books/search`), que faz proxy da Google Books API
/// com ranking de relevância/recência e esconde a API key. Rota pública (convidados também buscam).
struct GoogleBooksService {

    private var baseURL: String { AppConfig.baseURL }
    private let supportedLanguages = ["pt", "en"]

    /// Modo de ranking no backend: `search` (busca por título, relevância manda) ou
    /// `browse` (gênero/descoberta, favorece contemporâneos).
    enum Mode: String {
        case search
        case browse
    }

    func searchBooks(query: String, maxResults: Int = 20, startIndex: Int = 0, mode: Mode = .search) async throws -> [SearchBook] {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedQuery.count >= 2 else { return [] }

        var components = URLComponents(string: "\(baseURL)/books/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: cleanedQuery),
            URLQueryItem(name: "lang", value: appLanguageCode()),
            URLQueryItem(name: "maxResults", value: "\(maxResults)"),
            URLQueryItem(name: "startIndex", value: "\(startIndex)"),
            URLQueryItem(name: "mode", value: mode.rawValue)
        ]

        guard let url = components?.url else {
            throw GoogleBooksServiceError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw GoogleBooksServiceError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleBooksServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(BackendErrorResponse.self, from: data))?.error
                ?? "Book search failed (\(httpResponse.statusCode))."
            throw GoogleBooksServiceError.apiError(message: message)
        }

        do {
            return try JSONDecoder().decode([SearchBook].self, from: data)
        } catch {
            throw GoogleBooksServiceError.invalidResponse
        }
    }

    /// Resolve um ISBN escaneado num único livro (`GET /books/lookup`). `nil` quando o
    /// backend responde 404 — código de barras válido, mas sem correspondência: um
    /// resultado normal do fluxo de scanner, não um erro.
    func lookupISBN(_ isbn: String) async throws -> SearchBook? {
        var components = URLComponents(string: "\(baseURL)/books/lookup")
        components?.queryItems = [
            URLQueryItem(name: "isbn", value: isbn),
            URLQueryItem(name: "lang", value: appLanguageCode())
        ]

        guard let url = components?.url else {
            throw GoogleBooksServiceError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw GoogleBooksServiceError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleBooksServiceError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            return nil
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(BackendErrorResponse.self, from: data))?.error
                ?? "ISBN lookup failed (\(httpResponse.statusCode))."
            throw GoogleBooksServiceError.apiError(message: message)
        }

        do {
            return try JSONDecoder().decode(SearchBook.self, from: data)
        } catch {
            throw GoogleBooksServiceError.invalidResponse
        }
    }

    func loadImageData(from url: URL?) async -> Data? {
        guard let url else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            return data
        } catch {
            return nil
        }
    }

    /// Idioma preferido do usuário (pt/en), enviado ao backend como `langRestrict`.
    private func appLanguageCode() -> String {
        guard let preferred = Locale.preferredLanguages.first else {
            return "en"
        }
        let baseLanguage = Locale(identifier: preferred).language.languageCode?.identifier ?? "en"
        return supportedLanguages.contains(baseLanguage) ? baseLanguage : "en"
    }
}
