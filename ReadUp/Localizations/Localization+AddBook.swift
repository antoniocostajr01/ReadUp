//
//  Localization+AddBook.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum AddBook: LocalizationProtocol {
        case accessGallery
        case titlePlaceholder
        case authorPlaceholder
        case pagesPlaceholder
        case detailsPlaceholder
        case selectStatus
        case saveBook

        public var key: String.LocalizationValue {
            switch self {
            case .accessGallery: "addBook.accessGallery"
            case .titlePlaceholder: "addBook.titlePlaceholder"
            case .authorPlaceholder: "addBook.authorPlaceholder"
            case .pagesPlaceholder: "addBook.pagesPlaceholder"
            case .detailsPlaceholder: "addBook.detailsPlaceholder"
            case .selectStatus: "addBook.selectStatus"
            case .saveBook: "addBook.saveBook"
            }
        }
    }
}
