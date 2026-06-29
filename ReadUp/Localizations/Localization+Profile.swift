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
        case deleteAccount
        case deleteAccountConfirmTitle
        case deleteAccountConfirmMessage
        case deleteAccountConfirmAction

        public var key: String.LocalizationValue {
            switch self {
            case .title: "profile.title"
            case .defaultName: "profile.defaultName"
            case .signOut: "profile.signOut"
            case .signOutConfirmTitle: "profile.signOutConfirmTitle"
            case .yourGenres: "profile.yourGenres"
            case .noGenres: "profile.noGenres"
            case .deleteAccount: "profile.deleteAccount"
            case .deleteAccountConfirmTitle: "profile.deleteAccountConfirmTitle"
            case .deleteAccountConfirmMessage: "profile.deleteAccountConfirmMessage"
            case .deleteAccountConfirmAction: "profile.deleteAccountConfirmAction"
            }
        }
    }
}
