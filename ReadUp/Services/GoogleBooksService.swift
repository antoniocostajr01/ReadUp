import Foundation

struct GoogleBooksService {
    
    var googleBooksAPIKey: String {
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

        let encodedQuery = cleanedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanedQuery
        let endpoint = "https://www.googleapis.com/books/v1/volumes?q=intitle:\(encodedQuery)&maxResults=20&orderBy=relevance&key=\(googleBooksAPIKey)"

        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
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


