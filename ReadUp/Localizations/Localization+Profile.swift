//
//  Localization+Profile.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Profile: LocalizationProtocol {
        case title
        case defaultName
        case signOut
        case signOutConfirmTitle
        case yourGenres
        case noGenres

        public var key: String.LocalizationValue {
            switch self {
            case .title: "profile.title"
            case .defaultName: "profile.defaultName"
            case .signOut: "profile.signOut"
            case .signOutConfirmTitle: "profile.signOutConfirmTitle"
            case .yourGenres: "profile.yourGenres"
            case .noGenres: "profile.noGenres"
            }
        }
    }
}
