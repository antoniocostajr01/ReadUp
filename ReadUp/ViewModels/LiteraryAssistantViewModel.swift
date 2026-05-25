import Foundation
import FoundationModels
import SwiftUI

@MainActor
final class LiteraryAssistantViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var messages: [AIChatMessage] = [
        AIChatMessage(role: .assistant, text: Locale.current.language.languageCode?.identifier == "pt"
                      ? "Oi! Posso te ajudar com livros, leitura e recomendações personalizadas."
                      : "Hi! I can help with books, reading habits, and personalized recommendations.")
    ]
    @Published var recommendedBooks: [SearchBook] = []
    @Published var isThinking = false
    @Published var isSearchingRecommendations = false

    private var appLanguageCode: String {
        guard let preferred = Locale.preferredLanguages.first else { return "en" }
        let base = Locale(identifier: preferred).language.languageCode?.identifier ?? "en"
        return base == "pt" ? "pt" : "en"
    }

    private let model = SystemLanguageModel.default
    private lazy var session = LanguageModelSession(instructions: """
    You are a literary assistant for a reading app. You act as a highly knowledgeable literary guide.
    Your main goal is to guide the user through literary questions, help them find books, explain literary themes, and discuss authors or genres.
    You must ONLY talk about books, literature, authors, genres, reading habits, and recommendations.
    If the user asks about any non-literary topic, politely refuse and redirect to books.
    Format your responses naturally in plain text without excessive or weird markdown. You may use simple bolding for book titles.
    Keep responses concise, warm, and useful. When recommending books, ask about their taste if needed.
    CRITICAL: ALWAYS respond in the EXACT same language that the user used in their most recent message. For example, if they speak Portuguese, reply in Portuguese. If they speak English, reply in English.
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
        // Pequeno atraso para garantir que a animação de "pensando" apareça sempre, mesmo em operações rápidas
        try? await Task.sleep(nanoseconds: 600_000_000)

        guard isLiteraryTopic(text) else {
            let refusal = appLanguageCode == "pt"
            ? "Eu só posso conversar sobre livros e literatura. Me diga quais gêneros, autores ou temas você gosta."
            : "I can only talk about books and literature. Tell me what genres, authors, or themes you enjoy."
            messages.append(AIChatMessage(role: .assistant, text: refusal))
            isThinking = false
            return
        }

        let shouldFetchRecommendations = isRecommendationIntent(text)
        if shouldFetchRecommendations {
            recommendedBooks = []
            isSearchingRecommendations = true
        }

        let assistantReply = await generateAssistantReply(for: text)
        messages.append(AIChatMessage(role: .assistant, text: assistantReply))
        isThinking = false

        guard shouldFetchRecommendations else { return }

        let queries = await recommendationQueries(from: text)
        let books = await fetchRecommendations(queries: queries, booksService: booksService)
        recommendedBooks = books
        isSearchingRecommendations = false

        if books.isEmpty {
            let emptyText = appLanguageCode == "pt"
            ? "Ainda não encontrei boas opções agora. Tente me dizer gênero favorito, ritmo e estilo que você gosta."
            : "I couldn't find strong matches right now. Try giving me a favorite genre, pace, and mood."
            messages.append(AIChatMessage(role: .assistant, text: emptyText))
        } else {
            let foundText = appLanguageCode == "pt"
            ? "Encontrei algumas opções para seu gosto. Abra qualquer livro para ver detalhes e adicionar à biblioteca."
            : "I found some options for your taste. Open any book to see details and add it to your library."
            messages.append(AIChatMessage(role: .assistant, text: foundText))
        }
    }

    private func isLiteraryTopic(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let keywords = [
            "book", "books", "author", "authors", "novel", "novels", "read", "reading", "chapter", "chapters", "genre", "genres", "literature", "poetry", "fiction", "nonfiction", "story", "stories", "recommend",
            "livro", "livros", "autor", "autora", "romance", "leitura", "ler", "capítulo", "capitulos", "gênero", "genero", "literatura", "poesia", "ficção", "ficcao", "recomenda", "indica"
        ]

        return keywords.contains(where: { lowered.contains($0) })
    }

    private func isRecommendationIntent(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let triggers = [
            "recommend", "recomenda", "suggest", "sugira", "indica", "indique", "similar", "parecido", "quero livros", "me dê livros", "book suggestions", "book recommendation", "livros de", "books about"
        ]

        if triggers.contains(where: { lowered.contains($0) }) {
            return true
        }

        let genreHints = ["fantasy", "fantasia", "sci-fi", "ficção", "romance", "mystery", "suspense", "horror", "história", "history", "thriller", "poetry", "poesia"]
        return genreHints.contains(where: { lowered.contains($0) }) && (lowered.contains("livro") || lowered.contains("book"))
    }

    private func fetchRecommendations(queries: [String], booksService: GoogleBooksService) async -> [SearchBook] {
        var merged: [SearchBook] = []
        var usedIds = Set<String>()

        for query in queries.prefix(4) {
            do {
                let results = try await booksService.searchBooks(query: query)
                for book in results {
                    if !usedIds.contains(book.id) {
                        usedIds.insert(book.id)
                        merged.append(book)
                    }
                    if merged.count >= 10 {
                        return merged
                    }
                }
            } catch {
                continue
            }
        }
        
        // Se as queries falharam ou não retornaram nada, faça uma busca fallback robusta
        if merged.isEmpty {
            let fallbackQuery = appLanguageCode == "pt" ? "livros mais lidos best sellers" : "best selling popular books"
            do {
                let results = try await booksService.searchBooks(query: fallbackQuery)
                merged.append(contentsOf: results.prefix(10))
            } catch {
                // Em último caso, tenta algo muito básico
                if let basicResults = try? await booksService.searchBooks(query: "fiction"), !basicResults.isEmpty {
                    merged.append(contentsOf: basicResults.prefix(10))
                }
            }
        }

        return merged
    }

    private func recommendationQueries(from userMessage: String) async -> [String] {
        guard model.isAvailable else {
            return fallbackRecommendationQueries(from: userMessage)
        }

        do {
            let prompt = """
            Create exactly 4 short Google Books search queries based on this request:
            \(userMessage)

            Rules:
            - Output only 4 lines.
            - Each line starts with "- ".
            - Keep each query under 8 words.
            - Focus on books/genres/authors.
            """

            let response = try await session.respond(to: prompt)
            let lines = response.content
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.hasPrefix("-") }
                .map { $0.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            return lines.isEmpty ? fallbackRecommendationQueries(from: userMessage) : Array(lines.prefix(4))
        } catch {
            return fallbackRecommendationQueries(from: userMessage)
        }
    }

    private func fallbackRecommendationQueries(from userMessage: String) -> [String] {
        let lowered = userMessage.lowercased()
        let map: [(String, [String])] = [
            ("fantasy", ["fantasy books", "high fantasy novels", "epic fantasy books", "best fantasy authors"]),
            ("fantasia", ["livros fantasia", "fantasia épica", "romance fantasia", "autores de fantasia"]),
            ("sci-fi", ["science fiction books", "sci fi classics", "space opera books", "cyberpunk books"]),
            ("ficção científica", ["livros ficção científica", "distopia ficção", "sci fi livros", "space opera livros"]),
            ("romance", ["romance novels", "contemporary romance books", "romantic fiction", "romance best sellers"]),
            ("mystery", ["mystery thriller books", "detective novels", "crime fiction books", "suspense books"]),
            ("suspense", ["livros suspense", "romance policial", "thriller livros", "mistério livros"]),
            ("horror", ["horror novels", "psychological horror books", "gothic horror", "terror books"])
        ]

        for (keyword, queries) in map where lowered.contains(keyword) {
            return queries
        }

        if appLanguageCode == "pt" {
            return ["livros mais recomendados", "best sellers livros", userMessage, "livros populares"]
        }
        return ["recommended books", "best seller books", userMessage, "popular books"]
    }

    private func generateAssistantReply(for userMessage: String) async -> String {
        guard model.isAvailable else {
            return appLanguageCode == "pt"
            ? "O Apple Intelligence ainda não está disponível neste dispositivo. Posso ajudar com orientações literárias básicas enquanto isso."
            : "Apple Intelligence isn't available on this device yet. I can still help with basic literary guidance while it becomes available."
        }

        do {
            let response = try await session.respond(to: userMessage)
            return response.content
        } catch {
            return appLanguageCode == "pt"
            ? "Tive um problema para gerar a resposta agora. Tente novamente sobre livros, gêneros ou recomendações."
            : "I had trouble generating a response right now. Ask again about books, genres, or recommendations."
        }
    }
}

struct AIChatMessage: Identifiable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}
