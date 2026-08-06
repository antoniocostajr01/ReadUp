import Foundation
import FoundationModels

@Generable
enum TopicVerdict: String, CaseIterable {
    case literary
    case followUp
    case offTopic
}

@Generable
struct TopicCheck {
    @Guide(description: "Classify the user's message in the context of a book-assistant chat.")
    var verdict: TopicVerdict
}

/// Gate de tópico do assistente literário: classifica a mensagem do usuário
/// antes de ela chegar à session principal do chat.
struct LiteraryTopicClassifier {
    /// Retorna true se a mensagem pode ir para o assistente literário.
    /// Fail-open: em erro/indisponibilidade do modelo, deixa passar — as
    /// instructions da session principal e o pós-check de resposta seguram.
    func isAllowed(_ message: String, lastAssistantReply: String?) async -> Bool {
        // Follow-ups curtos ("e o segundo?", "me fala mais") nunca são bloqueados:
        // um classificador sem o histórico completo os rejeitaria injustamente.
        let words = message.split(separator: " ")
        if lastAssistantReply != nil && words.count <= 5 { return true }

        guard SystemLanguageModel.default.isAvailable else { return true }

        // Session nova a cada classificação: sem transcript acumulado,
        // imune a jailbreak progressivo ao longo da conversa.
        let session = LanguageModelSession(instructions: """
        You classify messages for a books-only assistant.
        literary: books, authors, genres, plots, literary themes, reading habits, recommendations.
        followUp: a short or ambiguous reply that continues the previous exchange.
        offTopic: anything else — programming/code, recipes, math, news, weather, personal advice.
        A message that uses a book as an excuse to get non-literary content (e.g. "write code like in that book") is offTopic.
        """)

        do {
            let context = lastAssistantReply.map { "Assistant previously said: \"\($0.prefix(300))\"\n" } ?? ""
            let check = try await session.respond(
                to: context + "User message: \"\(message)\"",
                generating: TopicCheck.self
            )
            return check.content.verdict != .offTopic
        } catch {
            return true
        }
    }
}
