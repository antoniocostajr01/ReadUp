//
//  Localization+ReadingSession.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum ReadingSession: LocalizationProtocol {
        case title
        case finish
        case leave
        case pagePrompt
        case pagePlaceholder
        case cantGoBack
        case exceedsPages
        case invalidPage
        case leaveTitle
        case stay
        case leaveMessage
        case currentPage
        case lockTip
        case lockSubtip

        public var key: String.LocalizationValue {
            switch self {
            case .title: "readingSession.title"
            case .finish: "readingSession.finish"
            case .leave: "readingSession.leave"
            case .pagePrompt: "readingSession.pagePrompt"
            case .pagePlaceholder: "readingSession.pagePlaceholder"
            case .cantGoBack: "readingSession.validation.cantGoBack"
            case .exceedsPages: "readingSession.validation.exceedsPages"
            case .invalidPage: "readingSession.invalidPage"
            case .leaveTitle: "readingSession.leaveTitle"
            case .stay: "readingSession.stay"
            case .leaveMessage: "readingSession.leaveMessage"
            case .currentPage: "readingSession.currentPage"
            case .lockTip: "readingSession.lockTip"
            case .lockSubtip: "readingSession.lockSubtip"
            }
        }
    }
}
