//
//  Localization+Search.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Search: LocalizationProtocol {
        case title
        case placeholder
        case seeAll
        case discover
        case loadingDiscovery
        case browseByGenre
        case searching
        case failed
        case noResults
        case tryAnother
        case noMoreResults
        case manualEntryHint
        case manualEntryDescription
        case addManually
        case addThisBookManually
        case catalogCaveat
        case noCover
        case pageCountMissing
        case noMatchTitle
        case noMatchSubtitle

        /// "443 p." — a unidade depende do idioma, por isso interpola em vez de concatenar.
        public static func pageCount(_ count: Int) -> String {
            String(localized: "search.pageCount \(count)", bundle: .main)
        }

        public var key: String.LocalizationValue {
            switch self {
            case .title: "search.title"
            case .placeholder: "search.placeholder"
            case .seeAll: "search.seeAll"
            case .discover: "search.discover"
            case .loadingDiscovery: "search.loadingDiscovery"
            case .browseByGenre: "search.browseByGenre"
            case .searching: "search.searching"
            case .failed: "search.failed"
            case .noResults: "search.noResults"
            case .tryAnother: "search.tryAnother"
            case .noMoreResults: "search.noMoreResults"
            case .manualEntryHint: "search.manualEntryHint"
            case .manualEntryDescription: "search.manualEntryDescription"
            case .addManually: "search.addManually"
            case .addThisBookManually: "search.addThisBookManually"
            case .catalogCaveat: "search.catalogCaveat"
            case .noCover: "search.noCover"
            case .pageCountMissing: "search.pageCountMissing"
            case .noMatchTitle: "search.noMatchTitle"
            case .noMatchSubtitle: "search.noMatchSubtitle"
            }
        }
    }
}
