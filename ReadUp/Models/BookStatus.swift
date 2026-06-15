//
//  BookStatus.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//

import Foundation

enum BookStatus: String, Codable, CaseIterable {
    // Raw values alinhados ao enum BookStatus do backend (Prisma).
    case read = "read"
    case reading = "reading"
    case iWantToRead = "i_want_to_read"
    case abandoned = "abandoned"
    case rereading = "rereading"

    var displayName: String {
        switch self {
        case .read: String(localized: "bookStatus.read", bundle: .main)
        case .reading: String(localized: "bookStatus.reading", bundle: .main)
        case .iWantToRead: String(localized: "bookStatus.iWantToRead", bundle: .main)
        case .abandoned: String(localized: "bookStatus.abandoned", bundle: .main)
        case .rereading: String(localized: "bookStatus.rereading", bundle: .main)
        }
    }
}


