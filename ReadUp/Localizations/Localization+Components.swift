//
//  Localization+Components.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Components: LocalizationProtocol {
        case pageOf
        case startReading
        case continueReading
        case pagesCount

        public var key: String.LocalizationValue {
            switch self {
            case .pageOf: "components.pageOf"
            case .startReading: "components.startReading"
            case .continueReading: "components.continueReading"
            case .pagesCount: "components.pagesCount"
            }
        }
    }
}
