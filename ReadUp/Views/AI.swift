import SwiftUI
import FoundationModels

struct AI: View {
    private var isPortuguese: Bool {
        Locale.current.language.languageCode?.identifier == "pt"
    }

    private var starterPrompts: [String] {
        isPortuguese
        ? [
            "Me recomende livros de fantasia",
            "Quero livros parecidos com 1984",
            "Sou iniciante em ficção científica"
        ]
        : [
            "Recommend fantasy books",
            "Suggest books similar to 1984",
            "I'm new to science fiction"
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text(isPortuguese ? "Converse sobre livros, descubra recomendações e encontre seu próximo título." : "Talk about books, get recommendations, and find your next read.")
                    .foregroundStyle(.secundaryLabel)

                capabilityCard(icon: "book.closed.fill", title: isPortuguese ? "Recomendações" : "Recommendations", description: isPortuguese ? "A IA entende seu gosto e sugere livros para você." : "The assistant understands your taste and suggests books.")
                capabilityCard(icon: "person.text.rectangle.fill", title: isPortuguese ? "Conversa Literária" : "Literary Chat", description: isPortuguese ? "Fale sobre autores, gêneros, ritmo de leitura e temas." : "Talk about authors, genres, reading pace, and themes.")
                capabilityCard(icon: "plus.circle.fill", title: isPortuguese ? "Adicionar à Biblioteca" : "Add to Library", description: isPortuguese ? "Veja capas, abra detalhes e adicione livros com status." : "View covers, open details, and add books with status.")

                Text(isPortuguese ? "Perguntas prontas" : "Quick prompts")
                    .font(.headline)

                VStack(spacing: 8) {
                    ForEach(starterPrompts, id: \.self) { prompt in
                        NavigationLink(destination: AIChatView(initialPrompt: prompt)) {
                            HStack {
                                Text(prompt)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                        }
                        .foregroundStyle(Color(uiColor: .label))
                    }
                }

                NavigationLink(destination: AIChatView(initialPrompt: nil)) {
                    Text(isPortuguese ? "Iniciar chat" : "Start chat")
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.emphasis)
                        )
                }
            }
            .padding(16)
        }
        .background(.backgroundPrimary)
        .navigationTitle("IA")
    }

    private func capabilityCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.emphasis)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secundaryLabel)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

struct AIChatView: View {
    @StateObject private var viewModel = LiteraryAssistantViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    private let service = GoogleBooksService()
    let initialPrompt: String?

    private var isPortuguese: Bool {
        Locale.current.language.languageCode?.identifier == "pt"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(viewModel.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }

                        if viewModel.isThinking {
                            typingIndicator
                        }

                        if viewModel.isSearchingRecommendations {
                            searchingRecommendationsCard
                            recommendationsSkeletonSection
                        }

                        if !viewModel.recommendedBooks.isEmpty {
                            recommendationsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        isInputFocused = false
                    }
                )
                .onTapGesture {
                    isInputFocused = false
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            composer
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.thinMaterial)
        }
        .background(.backgroundPrimary)
        .navigationTitle(isPortuguese ? "Chat Literário" : "Literary Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if let initialPrompt, viewModel.messages.count == 1 {
                Task {
                    await viewModel.sendUserMessage(initialPrompt, booksService: service)
                }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField(isPortuguese ? "Pergunte sobre livros..." : "Ask about books...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.emphasis))
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isThinking)
            .opacity((inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isThinking) ? 0.5 : 1)
        }
    }

    private func messageBubble(_ message: AIChatMessage) -> some View {
        HStack {
            if message.role == .assistant {
                Text(message.text)
                    .font(.body)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.emphasis)
                    )
            }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.emphasis)
            Text(isPortuguese ? "Pensando..." : "Thinking...")
                .font(.subheadline)
                .foregroundStyle(.secundaryLabel)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isPortuguese ? "Recomendados para você" : "Recommended for you")
                .font(.system(.title3, weight: .bold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.recommendedBooks) { book in
                        NavigationLink(destination: SearchBookDetails(book: book, service: service)) {
                            VStack(alignment: .leading, spacing: 8) {
                                AsyncImage(url: book.thumbnailURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    default:
                                        Color(uiColor: .tertiarySystemFill)
                                    }
                                }
                                .frame(width: 118, height: 170)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                Text(book.title)
                                    .font(.headline)
                                    .foregroundStyle(Color(uiColor: .label))
                                    .lineLimit(1)

                                Text(book.author)
                                    .font(.subheadline)
                                    .foregroundStyle(.secundaryLabel)
                                    .lineLimit(1)
                            }
                            .frame(width: 130, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var searchingRecommendationsCard: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.emphasis)
            Text(isPortuguese ? "Buscando recomendações para você..." : "Searching recommendations for you...")
                .font(.subheadline)
                .foregroundStyle(.secundaryLabel)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var recommendationsSkeletonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isPortuguese ? "Preparando sugestões..." : "Preparing suggestions...")
                .font(.system(.title3, weight: .bold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(uiColor: .tertiarySystemFill))
                                .frame(width: 118, height: 170)

                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color(uiColor: .tertiarySystemFill))
                                .frame(width: 110, height: 12)

                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color(uiColor: .tertiarySystemFill))
                                .frame(width: 80, height: 10)
                        }
                        .frame(width: 130, alignment: .leading)
                        .redacted(reason: .placeholder)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func sendMessage() async {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        inputText = ""
        await viewModel.sendUserMessage(message, booksService: service)
    }
}

@MainActor
final class LiteraryAssistantViewModel: ObservableObject {
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
    You are a literary assistant for a reading app.
    You must ONLY talk about books, literature, authors, genres, reading habits, and recommendations.
    If the user asks about any non-literary topic, politely refuse and redirect to books.
    Keep responses concise, warm, and useful.
    When recommending books, ask about user taste first if needed.
    Always respond in \(appLanguageCode == "pt" ? "Portuguese (Brazil)" : "English").
    """)

    func sendUserMessage(_ text: String, booksService: GoogleBooksService) async {
        messages.append(AIChatMessage(role: .user, text: text))

        guard isLiteraryTopic(text) else {
            let refusal = appLanguageCode == "pt"
            ? "Eu só posso conversar sobre livros e literatura. Me diga quais gêneros, autores ou temas você gosta."
            : "I can only talk about books and literature. Tell me what genres, authors, or themes you enjoy."
            messages.append(AIChatMessage(role: .assistant, text: refusal))
            return
        }

        let shouldFetchRecommendations = isRecommendationIntent(text)
        if shouldFetchRecommendations {
            recommendedBooks = []
            isSearchingRecommendations = true
        }

        isThinking = true
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
        return fallbackRecommendationQueries(from: userMessage)
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

#Preview {
    NavigationStack {
        AI()
    }
}
