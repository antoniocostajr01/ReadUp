//
//  Localization+Components.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Components: LocalizationProtocol {
        case pageOf
        case startReading
        case continueReading
        case pagesCount
        /// Unidades soltas, ao lado de um número serifado. O número e a unidade têm
        /// estilos diferentes, então não cabem na mesma string — daí o par
        /// singular/plural escolhido no Swift em vez de uma variação de plural do
        /// `.xcstrings`, que exigiria o número dentro do texto.
        ///
        /// ponytail: só dá conta de "one"/"other", que cobre en e pt-BR. Um idioma com
        /// mais formas (russo, árabe) precisaria das variações do catálogo.
        case unitPage
        case unitPages
        case unitDay
        case unitDays
        case unitMinutes

        public var key: String.LocalizationValue {
            switch self {
            case .pageOf: "components.pageOf"
            case .startReading: "components.startReading"
            case .continueReading: "components.continueReading"
            case .pagesCount: "components.pagesCount"
            case .unitPage: "components.unit.page"
            case .unitPages: "components.unit.pages"
            case .unitDay: "components.unit.day"
            case .unitDays: "components.unit.days"
            case .unitMinutes: "components.unit.minutes"
            }
        }
    }
}

public extension Localization.Components {
    /// A unidade que concorda com o número ao lado.
    static func pages(_ count: Int) -> String {
        (count == 1 ? Localization.Components.unitPage : .unitPages).string
    }

    static func days(_ count: Int) -> String {
        (count == 1 ? Localization.Components.unitDay : .unitDays).string
    }
}
