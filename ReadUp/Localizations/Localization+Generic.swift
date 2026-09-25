//
//  Localization+Generic.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Generic: LocalizationProtocol {
        case ok
        case cancel
        case close
        case confirm
        case delete
        case done
        case back
        case skip
        case add
        case save
        case or
        case `continue`
        case tryAgain
        case error
        case updateTitle
        case updateMessage
        case updateAction
        case notNow

        public var key: String.LocalizationValue {
            switch self {
            case .ok: "generic.ok"
            case .cancel: "generic.cancel"
            case .close: "generic.close"
            case .confirm: "generic.confirm"
            case .delete: "generic.delete"
            case .done: "generic.done"
            case .back: "generic.back"
            case .skip: "generic.skip"
            case .add: "generic.add"
            case .save: "generic.save"
            case .or: "generic.or"
            case .continue: "generic.continue"
            case .tryAgain: "generic.tryAgain"
            case .error: "generic.error"
            case .updateTitle: "generic.updateTitle"
            case .updateMessage: "generic.updateMessage"
            case .updateAction: "generic.updateAction"
            case .notNow: "generic.notNow"
            }
        }
    }
}
