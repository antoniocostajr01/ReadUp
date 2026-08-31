//
//  Localization+Tab.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Tab: LocalizationProtocol {
        case home
        case library
        case profile

        public var key: String.LocalizationValue {
            switch self {
            case .home: "tab.home"
            case .library: "tab.library"
            case .profile: "tab.profile"
            }
        }
    }
}
