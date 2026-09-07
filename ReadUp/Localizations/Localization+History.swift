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
        /// As três parcelas de "46 sessions · 21h 12m · 1,284 pages". Separadas porque
        /// cada número concorda com a sua própria unidade.
        case totalsSession
        case totalsSessions
        case totalsPage
        case totalsPages
        case sectionThisWeek
        case sectionEarlier

        public var key: String.LocalizationValue {
            switch self {
            case .title: "history.title"
            case .emptyTitle: "history.empty.title"
            case .emptySubtitle: "history.empty.subtitle"
            case .totalsSession: "history.totals.session"
            case .totalsSessions: "history.totals.sessions"
            case .totalsPage: "history.totals.page"
            case .totalsPages: "history.totals.pages"
            case .sectionThisWeek: "history.section.thisWeek"
            case .sectionEarlier: "history.section.earlier"
            }
        }
    }
}

public extension Localization.History {
    /// "46 sessions · 21h 12m · 1,284 pages".
    static func totals(sessions: Int, duration: String, pages: Int) -> String {
        let sessionsText = String(
            format: (sessions == 1 ? Localization.History.totalsSession : .totalsSessions).string,
            sessions
        )
        let pagesText = String(
            format: (pages == 1 ? Localization.History.totalsPage : .totalsPages).string,
            pages
        )
        return "\(sessionsText) · \(duration) · \(pagesText)"
    }
}
