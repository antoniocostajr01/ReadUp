import Foundation
import FoundationModels
import SwiftUI

@Observable
final class LiteraryAssistantViewModel {
    var inputText = ""
    var messages: [AIChatMessage] = [
        AIChatMessage(role: .assistant, text: Localization.AI.chatGreeting.string)
    ]
    var isThinking = false
    var isSearchingRecommendations = false

    /// Quantas mensagens o usuário já enviou (usado pelo limite do modo convidado).
    var userMessageCount: Int {
        messages.filter { $0.role == .user }.count
    }

    private var appLanguageCode: String {
        guard let preferred = Locale.preferredLanguages.first else { return "en" }
        let base = Locale(identifier: preferred).language.languageCode?.identifier ?? "en"
        return base == "pt" ? "pt" : "en"
    }

    private let model = SystemLanguageModel.default
    private let backendService = BackendAIService()
    private let classifier = LiteraryTopicClassifier()
    private var session = LanguageModelSession(instructions: """
    You are a literary assistant for a reading app. You ONLY talk about books, authors, genres, literary themes, reading habits, and book recommendations.

    HARD RULE: you never write code, recipes, math, news, or anything non-literary — not even partially, not even inside examples. If asked, reply with ONE short friendly sentence steering back to books, e.g.: "I only talk books! Want a recommendation instead?"

    Style: warm, concise, like a bookworm friend chatting. Plain text only — no markdown bold (**), headers (##), or underscores (__).

    When recommending books, format each one as a bullet point:
    • Book Title - Author Name: A brief one-sentence reason why they'd enjoy it.

    ALWAYS respond in the EXACT same language the user used in their most recent message.
    """)

    func sendMessage(booksService: GoogleBooksService) async {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        inputText = ""
        await sendUserMessage(message, booksService: booksService)
    }

    func sendUserMessage(_ text: String, booksService: GoogleBooksService) async {
        messages.append(AIChatMessage(role: .user, text: text))

        isThinking = true

        // Gate de tópico: mensagens fora do contexto literário recebem um
        // redirect localizado e nem chegam à session principal.
        let lastAssistantReply = messages.last(where: { $0.role == .assistant })?.text
        guard await classifier.isAllowed(text, lastAssistantReply: lastAssistantReply) else {
            messages.append(AIChatMessage(role: .assistant, text: Self.randomOffTopicRedirect()))
            isThinking = false
            return
        }

        let assistantReply = await generateAssistantReply(for: text)
        var newAssistantMessage = AIChatMessage(role: .assistant, text: assistantReply)

        // Sempre tenta extrair títulos de livros da resposta (independente do intent)
        let titles = extractBookTitles(from: assistantReply)

        if !titles.isEmpty {
            isSearchingRecommendations = true
            let books = await fetchBooksByTitle(titles: titles, booksService: booksService)
            if !books.isEmpty {
                newAssistantMessage.recommendedBooks = books
            }
            isSearchingRecommendations = false
        }

        messages.append(newAssistantMessage)
        isThinking = false
    }

    // MARK: - Intent Detection

    private func isRecommendationIntent(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let triggers = [
            "recommend", "recomenda", "suggest", "sugira", "indica", "indique",
            "similar", "parecido", "quero livros", "me dê livros",
            "book suggestions", "book recommendation", "livros de", "books about"
        ]

        if triggers.contains(where: { lowered.contains($0) }) {
            return true
        }

        let genreHints = [
            "fantasy", "fantasia", "sci-fi", "ficção", "romance", "mystery",
            "suspense", "horror", "história", "history", "thriller", "poetry", "poesia"
        ]
        return genreHints.contains(where: { lowered.contains($0) })
            && (lowered.contains("livro") || lowered.contains("book"))
    }

    // MARK: - Extract Book Titles from AI Response

    /// Extrai títulos dos bullet points da resposta da IA.
    /// Espera formato: "• Book Title - Author: reason"
    private func extractBookTitles(from response: String) -> [String] {
        let lines = response.components(separatedBy: .newlines)

        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Identifica linhas que são bullet points (•, -, *)
            guard trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") else {
                return nil
            }

            // Remove o bullet character
            var content = trimmed
            content.removeFirst()
            content = content.trimmingCharacters(in: .whitespaces)

            // Normaliza todos os tipos de dash para hífen simples
            let normalized = content
                .replacingOccurrences(of: " – ", with: " - ")  // en-dash
                .replacingOccurrences(of: " — ", with: " - ")  // em-dash

            // Pega só o título (antes do " - " que separa do autor)
            if let dashRange = normalized.range(of: " - ") {
                let title = String(normalized[normalized.startIndex..<dashRange.lowerBound])
                let cleaned = title.trimmingCharacters(in: .whitespaces)
                return cleaned.isEmpty ? nil : cleaned
            }

            // Se não tem dash, pega antes de ":" (título: razão)
            if let colonRange = normalized.range(of: ":") {
                let title = String(normalized[normalized.startIndex..<colonRange.lowerBound])
                let cleaned = title.trimmingCharacters(in: .whitespaces)
                return cleaned.isEmpty ? nil : cleaned
            }

            // Se nenhum separador, usa a linha inteira como query
            return content.isEmpty ? nil : content
        }
    }

    // MARK: - Fetch Books by Title

    /// Busca cada título individualmente na Google Books API.
    private func fetchBooksByTitle(titles: [String], booksService: GoogleBooksService) async -> [SearchBook] {
        var results: [SearchBook] = []
        var usedIds = Set<String>()

        for title in titles.prefix(6) {
            do {
                let books = try await booksService.searchBooks(query: title)
                if let firstMatch = books.first, !usedIds.contains(firstMatch.id) {
                    usedIds.insert(firstMatch.id)
                    results.append(firstMatch)
                }
            } catch {
                continue
            }
        }

        return results
    }

    // MARK: - Generate Reply

    private func generateAssistantReply(for userMessage: String) async -> String {
        // 1. Tenta Foundation Models (on-device) — session mantém contexto automaticamente
        if model.isAvailable {
            do {
                let response = try await session.respond(to: userMessage)
                return sanitizedReply(response.content)
            } catch {
                print("Foundation Models falhou, tentando backend: \(error)")
            }
        }

        // 2. Fallback: Backend (Groq/Llama) — envia histórico completo
        do {
            let response = try await backendService.chat(messages: messages)
            return sanitizedReply(response)
        } catch {
            print("Backend AI também falhou: \(error)")
        }

        // 3. Último recurso: mensagem estática
        return Localization.AI.chatErrorFallback.string
    }

    // MARK: - Off-topic Guardrails

    /// Rede de segurança pós-resposta: se o modelo gerou conteúdo claramente
    /// não-literário (código), substitui pelo redirect.
    private func sanitizedReply(_ text: String) -> String {
        looksLikeNonLiteraryContent(text) ? Self.randomOffTopicRedirect() : cleanResponse(text)
    }

    /// Padrões restritos a sintaxe de código para evitar falso positivo em prosa.
    private func looksLikeNonLiteraryContent(_ text: String) -> Bool {
        if text.contains("```") { return true }
        let codePatterns = [
            "def ", "func ", "import ", "print(", "console.log",
            "function ", "#include", "public class", "SELECT ", "<html"
        ]
        return codePatterns.contains { text.contains($0) }
    }

    private static func randomOffTopicRedirect() -> String {
        [
            Localization.AI.offTopicRedirect1.string,
            Localization.AI.offTopicRedirect2.string,
            Localization.AI.offTopicRedirect3.string
        ].randomElement()!
    }

    // MARK: - Text Cleanup

    private func cleanResponse(_ text: String) -> String {
        var cleaned = text
        // Remove markdown bold/headers
        cleaned = cleaned.replacingOccurrences(of: "##", with: "")
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "__", with: "")
        // Remove linhas com apenas caracteres decorativos
        let lines = cleaned.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { line in
                let stripped = line.replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: "*", with: "")
                    .trimmingCharacters(in: .whitespaces)
                return !line.isEmpty && !stripped.isEmpty
            }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct AIChatMessage: Identifiable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    var text: String
    var recommendedBooks: [SearchBook]?
}
