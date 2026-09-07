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

    let bookTitle: String
    let bookAuthor: String
    let startDate: Date
}
