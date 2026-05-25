import Foundation

enum GoogleBooksServiceError: LocalizedError {
    case invalidURL
    case apiError(message: String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .apiError(let message):
            return message
        case .invalidResponse:
            return "Invalid server response."
        }
    }
}

private struct GoogleBooksAPIErrorResponse: Decodable {
    struct APIError: Decodable {
        struct APIErrorItem: Decodable {
            let message: String?
        }
        let message: String?
        let errors: [APIErrorItem]?
    }
    let error: APIError?
}

struct GoogleBooksService {
    var apiKey: String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_BOOKS_API_KEY") as? String else {
            fatalError("A chave GOOGLE_BOOKS_API_KEY não foi encontrada no Info.plist")
        }
        return apiKey
    }

    private let supportedLanguages = ["pt", "en"]

    func searchBooks(query: String) async throws -> [SearchBook] {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedQuery.count >= 2 else { return [] }
        let preferredLanguageCode = appLanguageCode()

        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "intitle:\(cleanedQuery)"),
            URLQueryItem(name: "maxResults", value: "20"),
            URLQueryItem(name: "orderBy", value: "relevance"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components?.url else {
            throw GoogleBooksServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleBooksServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(GoogleBooksAPIErrorResponse.self, from: data) {
                let message = apiError.error?.message
                    ?? apiError.error?.errors?.first?.message
                    ?? "Google Books request failed (\(httpResponse.statusCode))."
                throw GoogleBooksServiceError.apiError(message: message)
            }
            throw GoogleBooksServiceError.apiError(message: "Google Books request failed (\(httpResponse.statusCode)).")
        }

        let decoded = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        return (decoded.items ?? []).compactMap { item in
            let info = item.volumeInfo
            let normalizedLanguage = normalizedLanguageCode(info.language)
            let description = info.description?.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let normalizedLanguage, supportedLanguages.contains(normalizedLanguage) else {
                return nil
            }

            guard let description, !description.isEmpty else {
                return nil
            }

            let rawURL = info.imageLinks?.thumbnail?.replacingOccurrences(of: "http://", with: "https://")
            return SearchBook(
                id: item.id,
                title: info.title,
                author: info.authors?.joined(separator: ", ") ?? String(localized: "search.unknown_author", defaultValue: "Unknown author"),
                details: description,
                numberOfPages: info.pageCount ?? 0,
                languageCode: normalizedLanguage,
                thumbnailURL: rawURL.flatMap(URL.init(string:))
            )
        }
        .sorted { lhs, rhs in
            (lhs.languageCode == preferredLanguageCode ? 0 : 1) < (rhs.languageCode == preferredLanguageCode ? 0 : 1)
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

    private func appLanguageCode() -> String {
        guard let preferred = Locale.preferredLanguages.first else {
            return "en"
        }

        let baseLanguage = Locale(identifier: preferred).language.languageCode?.identifier ?? "en"
        return supportedLanguages.contains(baseLanguage) ? baseLanguage : "en"
    }

    private func normalizedLanguageCode(_ languageCode: String?) -> String? {
        guard let languageCode else { return nil }
        let normalized = Locale(identifier: languageCode).language.languageCode?.identifier ?? languageCode.lowercased()
        return normalized
    }
}
