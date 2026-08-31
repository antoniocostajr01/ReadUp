//
//  Localization+BookDetails.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum BookDetails: LocalizationProtocol {
        case title
        case editBook
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
        case statusLabel
        case continueReading
        case startReading
        case addedToLibrary
        case addAnotherBook
        case pagesLabel
        case currentLabel
        case doneLabel

        public var key: String.LocalizationValue {
            switch self {
            case .title: "bookDetails.title"
            case .editBook: "bookDetails.editBook"
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
            case .statusLabel: "bookDetails.statusLabel"
            case .continueReading: "bookDetails.continueReading"
            case .startReading: "bookDetails.startReading"
            case .addedToLibrary: "bookDetails.addedToLibrary"
            case .addAnotherBook: "bookDetails.addAnotherBook"
            case .pagesLabel: "bookDetails.pagesLabel"
            case .currentLabel: "bookDetails.currentLabel"
            case .doneLabel: "bookDetails.doneLabel"
            }
        }
    }
}
