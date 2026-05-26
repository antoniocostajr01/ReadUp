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

                CapabilityCard(icon: "book.closed.fill", title: isPortuguese ? "Recomendações" : "Recommendations", description: isPortuguese ? "A IA entende seu gosto e sugere livros para você." : "The assistant understands your taste and suggests books.")
                CapabilityCard(icon: "person.text.rectangle.fill", title: isPortuguese ? "Conversa Literária" : "Literary Chat", description: isPortuguese ? "Fale sobre autores, gêneros, ritmo de leitura e temas." : "Talk about authors, genres, reading pace, and themes.")
                CapabilityCard(icon: "plus.circle.fill", title: isPortuguese ? "Adicionar à Biblioteca" : "Add to Library", description: isPortuguese ? "Veja capas, abra detalhes e adicione livros com status." : "View covers, open details, and add books with status.")

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

}

struct AIChatView: View {
    @StateObject private var viewModel = LiteraryAssistantViewModel()
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
                            AIMessageBubble(message: message, service: service)
                                .id(message.id)
                        }

                        if viewModel.isSearchingRecommendations {
                            searchingRecommendationsCard
                            recommendationsSkeletonSection
                        }

                        if viewModel.isThinking {
                            typingIndicator
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
            TextField(isPortuguese ? "Pergunte sobre livros..." : "Ask about books...", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )

            Button {
                Task { await viewModel.sendMessage(booksService: service) }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.emphasis))
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isThinking)
            .opacity((viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isThinking) ? 0.5 : 1)
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
        let message = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        viewModel.inputText = ""
        await viewModel.sendUserMessage(message, booksService: service)
    }
}



#Preview {
    NavigationStack {
        AI()
    }
}
