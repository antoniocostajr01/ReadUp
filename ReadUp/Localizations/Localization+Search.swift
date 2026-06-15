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
            }
        }
    }
}
