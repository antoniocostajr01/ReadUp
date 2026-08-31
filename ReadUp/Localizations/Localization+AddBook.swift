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
        case isbnPlaceholder
        case selectStatus
        case saveBook
        case manualEntry
        case screenTitle
        case coverOptional
        case startingPageLabel
        case isbnLabel
        case descriptionLabel
        case pageCountNote

        public var key: String.LocalizationValue {
            switch self {
            case .accessGallery: "addBook.accessGallery"
            case .titlePlaceholder: "addBook.titlePlaceholder"
            case .authorPlaceholder: "addBook.authorPlaceholder"
            case .pagesPlaceholder: "addBook.pagesPlaceholder"
            case .detailsPlaceholder: "addBook.detailsPlaceholder"
            case .isbnPlaceholder: "addBook.isbnPlaceholder"
            case .selectStatus: "addBook.selectStatus"
            case .saveBook: "addBook.saveBook"
            case .manualEntry: "addBook.manualEntry"
            case .screenTitle: "addBook.screenTitle"
            case .coverOptional: "addBook.coverOptional"
            case .startingPageLabel: "addBook.startingPageLabel"
            case .isbnLabel: "addBook.isbnLabel"
            case .descriptionLabel: "addBook.descriptionLabel"
            case .pageCountNote: "addBook.pageCountNote"
            }
        }
    }
}
