//
//  Localization+Onboarding.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Onboarding: LocalizationProtocol {
        case getStarted
        case genresTitle
        case genresSubtitle
        case selectAtLeast
        case selected
        case alreadyHaveAccount
        case heroLine1
        case heroLine2
        case heroLine3
        case welcomeBody
        case continueAsGuest
        case skipForNow
        case genresTitleLine1
        case genresTitleLine2

        public var key: String.LocalizationValue {
            switch self {
            case .getStarted: "onboarding.getStarted"
            case .genresTitle: "onboarding.genres.title"
            case .genresSubtitle: "onboarding.genres.subtitle"
            case .selectAtLeast: "onboarding.genres.selectAtLeast"
            case .selected: "onboarding.genres.selected"
            case .alreadyHaveAccount: "onboarding.alreadyHaveAccount"
            case .heroLine1: "onboarding.hero.line1"
            case .heroLine2: "onboarding.hero.line2"
            case .heroLine3: "onboarding.hero.line3"
            case .welcomeBody: "onboarding.welcomeBody"
            case .continueAsGuest: "onboarding.continueAsGuest"
            case .skipForNow: "onboarding.skipForNow"
            case .genresTitleLine1: "onboarding.genres.titleLine1"
            case .genresTitleLine2: "onboarding.genres.titleLine2"
            }
        }
    }
}
