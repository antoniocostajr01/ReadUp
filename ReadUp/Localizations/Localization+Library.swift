//
//  Localization+Library.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Library: LocalizationProtocol {
        case title
        case emptyTitle
        case emptySubtitle

        public var key: String.LocalizationValue {
            switch self {
            case .title: "library.title"
            case .emptyTitle: "library.empty.title"
            case .emptySubtitle: "library.empty.subtitle"
            }
        }
    }
}
