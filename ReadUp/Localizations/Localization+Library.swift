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
        case searchPrompt
        case noResultsTitle
        case noResultsSubtitle

        public var key: String.LocalizationValue {
            switch self {
            case .title: "library.title"
            case .emptyTitle: "library.empty.title"
            case .emptySubtitle: "library.empty.subtitle"
            case .searchPrompt: "library.searchPrompt"
            case .noResultsTitle: "library.noResults.title"
            case .noResultsSubtitle: "library.noResults.subtitle"
            }
        }
    }
}
