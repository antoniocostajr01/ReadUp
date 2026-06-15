//
//  Localization+Generic.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Generic: LocalizationProtocol {
        case ok
        case cancel
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

        public var key: String.LocalizationValue {
            switch self {
            case .ok: "generic.ok"
            case .cancel: "generic.cancel"
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
            }
        }
    }
}
