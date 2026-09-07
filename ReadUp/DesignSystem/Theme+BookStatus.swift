//
//  Theme+BookStatus.swift
//  ReadUp
//

import SwiftUI

// MARK: - BookStatus

/// O lado de design do estado de leitura: a sua cor e o seu glifo.
///
/// Vive aqui, e não em `Models/BookStatus.swift`, porque é mapeamento de token —
/// o modelo só importa Foundation e não conhece cor nenhuma.
extension BookStatus {

    /// O ponto do chip de filtro e o círculo do badge na capa.
    var tint: Color {
        switch self {
        case .reading: Palette.statusReading
        case .rereading: Palette.statusRereading
        case .iWantToRead: Palette.statusWantToRead
        case .read: Palette.statusRead
        case .abandoned: Palette.statusAbandoned
        }
    }

    /// O SF Symbol do badge na capa.
    var icon: String {
        switch self {
        case .reading: "book.fill"
        case .rereading: "arrow.trianglehead.counterclockwise"
        case .iWantToRead: "bookmark.fill"
        case .read: "checkmark"
        case .abandoned: "hand.thumbsdown.fill"
        }
    }
}
