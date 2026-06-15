//
//  Book.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//

import Foundation

/// Livro do usuário. Espelha o `Book` do backend (fonte de verdade).
/// O nome `numberOfPages` é mantido para a UI; no JSON é `totalPages`.
struct Book: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var author: String
    var numberOfPages: Int
    var details: String
    var coverUrl: String?
    var status: BookStatus
    var progress: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, author, details, coverUrl, status, progress
        case numberOfPages = "totalPages"
    }

    init(
        id: String,
        title: String,
        author: String,
        numberOfPages: Int,
        details: String,
        coverUrl: String?,
        status: BookStatus,
        progress: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.numberOfPages = numberOfPages
        self.details = details
        self.coverUrl = coverUrl
        self.status = status
        self.progress = progress
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        // Campos opcionais no backend → defaults seguros para a UI.
        author = try c.decodeIfPresent(String.self, forKey: .author) ?? ""
        numberOfPages = try c.decodeIfPresent(Int.self, forKey: .numberOfPages) ?? 0
        details = try c.decodeIfPresent(String.self, forKey: .details) ?? ""
        coverUrl = try c.decodeIfPresent(String.self, forKey: .coverUrl)
        status = try c.decodeIfPresent(BookStatus.self, forKey: .status) ?? .reading
        progress = try c.decodeIfPresent(Int.self, forKey: .progress)
    }
}
