import Foundation
import FoundationModels
import SwiftUI

@Observable
final class LiteraryAssistantViewModel {
    var inputText = ""
    var messages: [AIChatMessage] = [
        AIChatMessage(role: .assistant, text: Locale.current.language.languageCode?.identifier == "pt"
                      ? "Oi! Posso te ajudar com livros, leitura e recomendações personalizadas."
                      : "Hi! I can help with books, reading habits, and personalized recommendations.")
    ]
    var isThinking = false
    var isSearchingRecommendations = false

    private var appLanguageCode: String {
        guard let preferred = Locale.preferredLanguages.first else { return "en" }
        let base = Locale(identifier: preferred).language.languageCode?.identifier ?? "en"
        return base == "pt" ? "pt" : "en"
    }

    private let model = SystemLanguageModel.default
    private let backendService = BackendAIService()
    private var session = LanguageModelSession(instructions: """
    You are a friendly, conversational, and highly knowledgeable literary assistant for a reading app.
    Act like a passionate bookworm chatting with a friend.
    Guide the user through literary questions, help them find books, explain literary themes, and discuss authors or genres naturally.
    Keep your responses human-like, warm, engaging, and concise. Avoid robotic or overly formal language.
    Only discuss books, literature, authors, genres, reading habits, and recommendations.
    If asked about non-literary topics, politely decline and offer to help with books instead.

    When recommending books, you MUST format each book as a bullet point like this:
    • Book Title - Author Name: A brief one-sentence reason why they'd enjoy it.

    Do NOT use markdown bold (**), headers (##), underscores (__), or other formatting. Use only plain text and bullet points (•).

    STRICT BOUNDARY: If the user asks about anything NOT related to books or literature, you MUST politely decline. Never provide the answer, not even partially.

    CRITICAL: ALWAYS respond in the EXACT same language that the user used in their most recent message.
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
        try? await Task.sleep(nanoseconds: 600_000_000)

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
                return cleanResponse(response.content)
            } catch {
                print("Foundation Models falhou, tentando backend: \(error)")
            }
        }

        // 2. Fallback: Backend (Groq/Llama) — envia histórico completo
        do {
            let response = try await backendService.chat(messages: messages)
            return cleanResponse(response)
        } catch {
            print("Backend AI também falhou: \(error)")
        }

        // 3. Último recurso: mensagem estática
        return appLanguageCode == "pt"
            ? "Tive um problema para gerar a resposta agora. Tente novamente sobre livros, gêneros ou recomendações."
            : "I had trouble generating a response right now. Ask again about books, genres, or recommendations."
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
