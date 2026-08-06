import Foundation

/// Resultado de busca de livro. Decodado da resposta do backend (`GET /books/search`),
/// que faz o proxy + ranking da Google Books API.
struct SearchBook: Identifiable, Hashable, Decodable {
    let id: String
    let title: String
    let author: String
    let details: String
    let numberOfPages: Int
    let languageCode: String?
    let thumbnailURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, title, author, details, language
        case numberOfPages = "totalPages"
        case coverUrl
    }

    init(
        id: String,
        title: String,
        author: String,
        details: String,
        numberOfPages: Int,
        languageCode: String?,
        thumbnailURL: URL?
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.details = details
        self.numberOfPages = numberOfPages
        self.languageCode = languageCode
        self.thumbnailURL = thumbnailURL
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        author = try c.decodeIfPresent(String.self, forKey: .author)
            ?? String(localized: "search.unknown_author", defaultValue: "Unknown author")
        details = try c.decodeIfPresent(String.self, forKey: .details) ?? ""
        numberOfPages = try c.decodeIfPresent(Int.self, forKey: .numberOfPages) ?? 0
        languageCode = try c.decodeIfPresent(String.self, forKey: .language)
        let cover = try c.decodeIfPresent(String.self, forKey: .coverUrl)
        thumbnailURL = cover.flatMap(URL.init(string:))
    }
}
