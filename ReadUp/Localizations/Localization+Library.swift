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
        case searchOption
        case addManually
        case scan

        /// "1 book" / "2 books" — plural resolvido pelo xcstrings, por isso é uma
        /// função com interpolação e não um `case` (a contagem tem que entrar na chave).
        public static func bookCount(_ count: Int) -> String {
            String(localized: "library.shelfCount \(count)", bundle: .main)
        }

        public var key: String.LocalizationValue {
            switch self {
            case .title: "library.title"
            case .emptyTitle: "library.empty.title"
            case .emptySubtitle: "library.empty.subtitle"
            case .searchPrompt: "library.searchPrompt"
            case .noResultsTitle: "library.noResults.title"
            case .noResultsSubtitle: "library.noResults.subtitle"
            case .searchOption: "library.addMenu.search"
            case .addManually: "library.addMenu.addManually"
            case .scan: "library.addMenu.scan"
            }
        }
    }
}
