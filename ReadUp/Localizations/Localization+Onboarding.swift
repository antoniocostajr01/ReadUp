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
        case skip
        case addTitle
        case addSubtitle
        case addScanTitle
        case addScanBody
        case addSearchTitle
        case addSearchBody
        case addManualTitle
        case addManualBody
        case liveTitle
        case liveSubtitle
        case liveNote
        case liveCurrentSession
        case liveTimeLabel

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
            case .skip: "onboarding.skip"
            case .addTitle: "onboarding.add.title"
            case .addSubtitle: "onboarding.add.subtitle"
            case .addScanTitle: "onboarding.add.scan.title"
            case .addScanBody: "onboarding.add.scan.body"
            case .addSearchTitle: "onboarding.add.search.title"
            case .addSearchBody: "onboarding.add.search.body"
            case .addManualTitle: "onboarding.add.manual.title"
            case .addManualBody: "onboarding.add.manual.body"
            case .liveTitle: "onboarding.live.title"
            case .liveSubtitle: "onboarding.live.subtitle"
            case .liveNote: "onboarding.live.note"
            case .liveCurrentSession: "onboarding.live.currentSession"
            case .liveTimeLabel: "onboarding.live.timeLabel"
            }
        }
    }
}
