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
        case totalCompletion
        case finalThoughts
        case thoughtsPlaceholder
        case editSession
        case saveChanges
        case backToHome
        case changesSaved
        case changesFailed
        case ofPages

        // MARK: Fluxo de compartilhamento

        case share
        case storyOverline
        case madeWith
        case optionPhotoTitle
        case optionPhotoCaption
        case optionCardTitle
        case optionCardCaption
        case continueAction
        case cameraBack
        case cameraFront
        case cameraDenied
        case cameraOpenSettings
        case editorHint
        case editorAddText
        case editorDone
        case editorTextColor
        case shareToStories
        case shareOther
        case readyCaption

        public var key: String.LocalizationValue {
            switch self {
            case .title: "sessionSummary.title"
            case .pagesRead: "sessionSummary.pagesRead"
            case .sessionTime: "sessionSummary.sessionTime"
            case .totalCompletion: "sessionSummary.totalCompletion"
            case .finalThoughts: "sessionSummary.finalThoughts"
            case .thoughtsPlaceholder: "sessionSummary.thoughtsPlaceholder"
            case .editSession: "sessionSummary.editSession"
            case .saveChanges: "sessionSummary.saveChanges"
            case .backToHome: "sessionSummary.backToHome"
            case .changesSaved: "sessionSummary.changesSaved"
            case .changesFailed: "sessionSummary.changesFailed"
            case .ofPages: "sessionSummary.ofPages"
            case .share: "sessionSummary.share"
            case .storyOverline: "sessionSummary.storyOverline"
            case .madeWith: "sessionSummary.madeWith"
            case .optionPhotoTitle: "sessionSummary.optionPhotoTitle"
            case .optionPhotoCaption: "sessionSummary.optionPhotoCaption"
            case .optionCardTitle: "sessionSummary.optionCardTitle"
            case .optionCardCaption: "sessionSummary.optionCardCaption"
            case .continueAction: "sessionSummary.continueAction"
            case .cameraBack: "sessionSummary.cameraBack"
            case .cameraFront: "sessionSummary.cameraFront"
            case .cameraDenied: "sessionSummary.cameraDenied"
            case .cameraOpenSettings: "sessionSummary.cameraOpenSettings"
            case .editorHint: "sessionSummary.editorHint"
            case .editorAddText: "sessionSummary.editorAddText"
            case .editorDone: "sessionSummary.editorDone"
            case .editorTextColor: "sessionSummary.editorTextColor"
            case .shareToStories: "sessionSummary.shareToStories"
            case .shareOther: "sessionSummary.shareOther"
            case .readyCaption: "sessionSummary.readyCaption"
            }
        }
    }
}
