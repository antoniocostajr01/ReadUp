//
//  Localization+AI.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum AI: LocalizationProtocol {
        case title
        case description
        case quickSuggestions
        case thinking
        case startConversation
        case chatTitle
        case chatPlaceholder
        case chatGreeting
        case chatErrorFallback
        case recommendedForYou
        case fallback1
        case fallback2
        case fallback3

        public var key: String.LocalizationValue {
            switch self {
            case .title: "ai.title"
            case .description: "ai.description"
            case .quickSuggestions: "ai.quickSuggestions"
            case .thinking: "ai.thinking"
            case .startConversation: "ai.startConversation"
            case .chatTitle: "ai.chat.title"
            case .chatPlaceholder: "ai.chat.placeholder"
            case .chatGreeting: "ai.chat.greeting"
            case .chatErrorFallback: "ai.chat.errorFallback"
            case .recommendedForYou: "ai.recommendedForYou"
            case .fallback1: "ai.fallback1"
            case .fallback2: "ai.fallback2"
            case .fallback3: "ai.fallback3"
            }
        }
    }
}
