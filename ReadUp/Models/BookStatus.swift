//
//  BookStatus.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//

import Foundation

enum BookStatus: String, Codable, CaseIterable {
    case read = "Read"
    case reading = "Reading"
    case iWantToRead = "I want to read"
    case abandoned = "Abandoned"
    case rereading = "Rereading"

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


