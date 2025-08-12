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
}


