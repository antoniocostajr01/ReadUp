//
//  Localization+BookDetails.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum BookDetails: LocalizationProtocol {
        case title
        case deleteBook
        case changeStatus
        case selectStatus
        case deleteConfirmTitle
        case deleteConfirmMessage
        case readLess
        case readMore
        case alreadyInLibrary
        case saving
        case addToLibrary
        case saveSuccess
        case saveError

        public var key: String.LocalizationValue {
            switch self {
            case .title: "bookDetails.title"
            case .deleteBook: "bookDetails.deleteBook"
            case .changeStatus: "bookDetails.changeStatus"
            case .selectStatus: "bookDetails.selectStatus"
            case .deleteConfirmTitle: "bookDetails.deleteConfirmTitle"
            case .deleteConfirmMessage: "bookDetails.deleteConfirmMessage"
            case .readLess: "bookDetails.readLess"
            case .readMore: "bookDetails.readMore"
            case .alreadyInLibrary: "bookDetails.alreadyInLibrary"
            case .saving: "bookDetails.saving"
            case .addToLibrary: "bookDetails.addToLibrary"
            case .saveSuccess: "bookDetails.saveSuccess"
            case .saveError: "bookDetails.saveError"
            }
        }
    }
}
