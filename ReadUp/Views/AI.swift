import SwiftUI
import FoundationModels

struct AI: View {

    @State private var suggestedPrompts: [String] = []
    @State private var isLoading: Bool = true
    @State private var isPulsating: Bool = false
    @State private var navigateToChat: Bool = false
    @State private var selectedPrompt: String? = nil

    private let backendService = BackendAIService()

    @State private var session: LanguageModelSession = {
        let deviceLanguage = Locale.preferredLanguages.first ?? "en"

        return LanguageModelSession(instructions: """
            You MUST generate the prompts in the language corresponding to this locale code: \(deviceLanguage).

            ROLE: You are a librarian assistant inside a reading-tracker app. Your sole purpose is to generate exactly 3 short starter prompts that a reader would ask a real librarian.

            WHAT MAKES A GOOD PROMPT:
            - Direct, practical requests a person would say at a library counter.
            - Asking for book recommendations by genre, mood, length, or audience.
            - Asking for books similar to a well-known title or author.
            - Asking for help choosing what to read next based on concrete criteria.

            WHAT TO AVOID:
            - Conversational or personal questions ("What do you think about...", "Do you like...").
            - Anything that requires subjective opinion, feelings, or debate.
            - Reading tips, habits, or productivity advice ("How to read faster", "How to build a reading habit").
            - Greetings, introductions, or filler text of any kind.

            OUTPUT FORMAT:
            - Exactly 3 prompts, each on its own line.
            - No numbering, no bullet points, no quotes, no extra text.
            - Each prompt must be under 8 words.
            - Vary the category across the 3 prompts (e.g. one by genre, one by similarity, one by criteria).
        """)
    }()
  

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Pergunte como faria a um bibliotecário: peça indicações, descubra livros parecidos ou encontre sua próxima leitura.")
                    .foregroundStyle(.secundaryLabel)

                Text("Sugestões rápidas")
                    .font(.headline)
                    .padding(.top, 24)
                
                VStack(spacing: 8) {
                    if isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "apple.intelligence")
                                .font(.system(size: 32, weight: .regular))
                                .foregroundStyle(.emphasis)
                                .symbolEffect(.pulse, options: .repeating, value: isPulsating)
                                .onAppear { isPulsating.toggle() }
                            
                            Text("Pensando em boas perguntas...")
                                .font(.subheadline)
                                .foregroundStyle(.secundaryLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .transition(.opacity)
                    } else {
                        ForEach(suggestedPrompts, id: \.self) { prompt in
                            AIQuickPromptCard(promptText: prompt) {
                                selectedPrompt = prompt
                                navigateToChat = true
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .animation(.easeOut(duration: 0.6), value: isLoading)

                NavigationLink(destination: AIChatView()) {
                    Text("Começar conversa")
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.emphasis)
                        )
                }
                .padding(.top, 16)
            }
            .padding(16)
        }
        .background(.backgroundPrimary)
        .navigationTitle("IA")
        .navigationDestination(isPresented: $navigateToChat) {
            AIChatView(initialPrompt: selectedPrompt)
        }
        .task {
            await fetchStarterPrompts()
        }
    }
    
    func fetchStarterPrompts() async {
        guard suggestedPrompts.isEmpty else { return }

        isLoading = true

        let staticFallback = [
            "Me indique livros de aventura",
            "Livros parecidos com 1984",
            "Um clássico curto para iniciantes"
        ]

        // 1. Tenta usar Foundation Models (on-device)
        if SystemLanguageModel.default.isAvailable {
            do {
                let response = try await session.respond(to: "Generate 3 starter prompts.").content

                let unwantedCharacters = CharacterSet(charactersIn: "*\"-•–—")
                    .union(.decimalDigits)
                    .union(CharacterSet(charactersIn: ".):"))

                let prompts = response.components(separatedBy: .newlines)
                    .map { line in
                        var cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        while let first = cleaned.unicodeScalars.first,
                              unwantedCharacters.contains(first) || first == "-" {
                            cleaned = String(cleaned.dropFirst())
                                .trimmingCharacters(in: .whitespaces)
                        }
                        return cleaned.trimmingCharacters(in: unwantedCharacters)
                    }
                    .filter { !$0.isEmpty }
                    .prefix(3)

                await MainActor.run {
                    self.suggestedPrompts = Array(prompts)
                    self.isLoading = false
                }
                return
            } catch {
                print("Foundation Models falhou, tentando backend: \(error)")
            }
        }

        // 2. Fallback: tenta gerar via backend (Groq/Llama)
        do {
            let promptMessage = AIChatMessage(
                role: .user,
                text: "Generate exactly 3 short book recommendation prompts a reader would ask a librarian. One per line, no numbering, no quotes, under 8 words each. Respond in \(Locale.preferredLanguages.first ?? "en")."
            )
            let response = try await backendService.chat(messages: [promptMessage])

            let prompts = response.components(separatedBy: CharacterSet.newlines)
                .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(3)

            if !prompts.isEmpty {
                await MainActor.run {
                    self.suggestedPrompts = Array(prompts)
                    self.isLoading = false
                }
                return
            }
        } catch {
            print("Backend AI também falhou: \(error)")
        }

        // 3. Último recurso: prompts estáticos
        await MainActor.run {
            self.suggestedPrompts = staticFallback
            self.isLoading = false
        }
    }
}

struct AIQuickPromptCard: View {
    let promptText: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.emphasis)
                
                Text(promptText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AI()
    }
}
