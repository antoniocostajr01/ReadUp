//
//  Localization+History.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum History: LocalizationProtocol {
        case title
        case emptyTitle
        case emptySubtitle

        public var key: String.LocalizationValue {
            switch self {
            case .title: "history.title"
            case .emptyTitle: "history.empty.title"
            case .emptySubtitle: "history.empty.subtitle"
            }
        }
    }
}
