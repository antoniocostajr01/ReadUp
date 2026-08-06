//
//  Localization+SessionSummary.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum SessionSummary: LocalizationProtocol {
        case title
        case pagesRead
        case sessionTime
        case mins
        case totalCompletion
        case finalThoughts
        case thoughtsPlaceholder
        case saveSession
        case totalProgress
        case ofPages
        case shareToInstagram
        case clipboardInstruction
        case clipboardCopied

        public var key: String.LocalizationValue {
            switch self {
            case .title: "sessionSummary.title"
            case .pagesRead: "sessionSummary.pagesRead"
            case .sessionTime: "sessionSummary.sessionTime"
            case .mins: "sessionSummary.mins"
            case .totalCompletion: "sessionSummary.totalCompletion"
            case .finalThoughts: "sessionSummary.finalThoughts"
            case .thoughtsPlaceholder: "sessionSummary.thoughtsPlaceholder"
            case .saveSession: "sessionSummary.saveSession"
            case .totalProgress: "sessionSummary.totalProgress"
            case .ofPages: "sessionSummary.ofPages"
            case .shareToInstagram: "sessionSummary.shareToInstagram"
            case .clipboardInstruction: "sessionSummary.clipboardInstruction"
            case .clipboardCopied: "sessionSummary.clipboardCopied"
            }
        }
    }
}
