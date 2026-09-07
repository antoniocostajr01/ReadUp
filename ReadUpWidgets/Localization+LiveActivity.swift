//
//  Localization+LiveActivity.swift
//  ReadUpWidgets
//

import Foundation

/// As duas etiquetas do card. A extensão não enxerga o `Localizable.xcstrings` do
/// app — resolve contra o bundle dela —, então as strings vivem no catálogo desta
/// pasta e este enum é a versão mínima do padrão `Localization.<Área>` do app.
enum Localization {
    enum LiveActivity {
        static let currentSession = String(localized: "liveActivity.currentSession", defaultValue: "CURRENT SESSION")
        static let time = String(localized: "liveActivity.time", defaultValue: "TIME")
    }
}
