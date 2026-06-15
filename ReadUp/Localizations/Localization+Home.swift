//
//  Localization+Home.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Home: LocalizationProtocol {
        case greetingMorning
        case greetingAfternoon
        case greetingEvening
        case metricDayStreak
        case metricAverageTime
        case recentActivity
        case alertNoBooksTitle
        case alertNoBooksMessage
        case emptyTitle
        case emptySubtitle
        case addBook

        public var key: String.LocalizationValue {
            switch self {
            case .greetingMorning: "home.greeting.morning"
            case .greetingAfternoon: "home.greeting.afternoon"
            case .greetingEvening: "home.greeting.evening"
            case .metricDayStreak: "home.metric.dayStreak"
            case .metricAverageTime: "home.metric.averageTime"
            case .recentActivity: "home.recentActivity"
            case .alertNoBooksTitle: "home.alert.noBooksTitle"
            case .alertNoBooksMessage: "home.alert.noBooksMessage"
            case .emptyTitle: "home.empty.title"
            case .emptySubtitle: "home.empty.subtitle"
            case .addBook: "home.addBook"
            }
        }
    }
}
