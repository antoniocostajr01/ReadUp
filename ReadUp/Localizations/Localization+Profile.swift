//
//  Localization+Profile.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Profile: LocalizationProtocol {
        case title
        case editProfile
        case notifications
        case statBooks
        case statSessions
        case statStreak
        case defaultName
        case changePhoto
        case removePhoto
        case editName
        case namePlaceholder
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
            case .editProfile: "profile.editProfile"
            case .notifications: "profile.notifications"
            case .statBooks: "profile.stat.books"
            case .statSessions: "profile.stat.sessions"
            case .statStreak: "profile.stat.streak"
            case .defaultName: "profile.defaultName"
            case .changePhoto: "profile.changePhoto"
            case .removePhoto: "profile.removePhoto"
            case .editName: "profile.editName"
            case .namePlaceholder: "profile.namePlaceholder"
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
