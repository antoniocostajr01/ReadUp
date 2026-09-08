//
//  ReadingSessionAttributes.swift
//  ReadUp
//

import ActivityKit
import Foundation

/// Contrato da Live Activity da sessão de leitura, compartilhado entre o app e a
/// extensão de widget.
///
/// Nada aqui muda enquanto a sessão corre: o cronômetro é derivado de `startDate`
/// pelo próprio SwiftUI (`Text(_:style: .timer)`), então a Live Activity continua
/// contando sozinha, sem update nenhum e sem push, mesmo com o app suspenso — que
/// é exatamente o caso de uso, já que a tela de sessão pede para o usuário
/// bloquear o telefone (`readingSession.lockTip`).
struct ReadingSessionAttributes: ActivityAttributes {
    /// Vazio de propósito: a sessão não tem estado dinâmico além do tempo, e o
    /// tempo é desenhado a partir de `startDate`.
    struct ContentState: Codable, Hashable {}

    /// Horizonte da sessão: teto do cronômetro e idade máxima do card. Uma sessão
    /// esquecida (app morto, usuário dormiu) envelhece sozinha em vez de morar no
    /// lock screen para sempre.
    static let maxDuration: TimeInterval = 8 * 60 * 60

    let bookTitle: String
    let bookAuthor: String
    let startDate: Date

    /// A janela que `Text(timerInterval:)` desenha.
    var timerRange: ClosedRange<Date> {
        startDate...startDate.addingTimeInterval(Self.maxDuration)
    }
}
