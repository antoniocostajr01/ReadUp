//
//  Localization+Scan.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Scan: LocalizationProtocol {
        case title
        case instructions
        case resolving
        case notFound
        case addBooks
        case emptyList
        case cameraUnavailableTitle
        case cameraUnavailableMessage
        case close
        case scannedTitle
        case bookFound
        case catalogNote
        case barcodeRead
        case notInCatalogTitle
        case notInCatalogMessage
        case searchByTitle
        case enterManually

        public var key: String.LocalizationValue {
            switch self {
            case .title: "scan.title"
            case .instructions: "scan.instructions"
            case .resolving: "scan.resolving"
            case .notFound: "scan.notFound"
            case .addBooks: "scan.addBooks"
            case .emptyList: "scan.emptyList"
            case .cameraUnavailableTitle: "scan.cameraUnavailable.title"
            case .cameraUnavailableMessage: "scan.cameraUnavailable.message"
            case .close: "scan.close"
            case .scannedTitle: "scan.scannedTitle"
            case .bookFound: "scan.bookFound"
            case .catalogNote: "scan.catalogNote"
            case .barcodeRead: "scan.barcodeRead"
            case .notInCatalogTitle: "scan.notInCatalog.title"
            case .notInCatalogMessage: "scan.notInCatalog.message"
            case .searchByTitle: "scan.searchByTitle"
            case .enterManually: "scan.enterManually"
            }
        }
    }
}
