import Foundation

struct GoogleBooksResponse: Decodable {
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Decodable {
    let id: String
    let volumeInfo: GoogleVolumeInfo
}

struct GoogleVolumeInfo: Decodable {
    let title: String
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let language: String?
    let imageLinks: GoogleImageLinks?
}

struct GoogleImageLinks: Decodable {
    let thumbnail: String?
}

struct SearchBook: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let details: String
    let numberOfPages: Int
    let languageCode: String?
    let thumbnailURL: URL?
}
