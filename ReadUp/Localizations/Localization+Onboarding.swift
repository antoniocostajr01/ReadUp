//
//  Localization+Onboarding.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Onboarding: LocalizationProtocol {
        case next
        case getStarted
        case page1Subtitle
        case page2Subtitle
        case page3Title
        case page3Subtitle
        case genresTitle
        case genresSubtitle
        case selectAtLeast
        case selected

        public var key: String.LocalizationValue {
            switch self {
            case .next: "onboarding.next"
            case .getStarted: "onboarding.getStarted"
            case .page1Subtitle: "onboarding.page1.subtitle"
            case .page2Subtitle: "onboarding.page2.subtitle"
            case .page3Title: "onboarding.page3.title"
            case .page3Subtitle: "onboarding.page3.subtitle"
            case .genresTitle: "onboarding.genres.title"
            case .genresSubtitle: "onboarding.genres.subtitle"
            case .selectAtLeast: "onboarding.genres.selectAtLeast"
            case .selected: "onboarding.genres.selected"
            }
        }
    }
}
