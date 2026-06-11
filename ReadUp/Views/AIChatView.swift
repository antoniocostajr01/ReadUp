//
//  AIChatView.swift
//  ReadUp
//
//  Created by Antonio Costa on 26/05/26.
//

import Foundation
import SwiftUI
import FoundationModels

// MARK: - Models
enum MessageRole: Equatable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let role: MessageRole
    var isAnimating: Bool = false
}


struct AIChatView: View {
    var initialPrompt: String?

    init(initialPrompt: String? = nil) {
        self.initialPrompt = initialPrompt
    }

    @State private var messages: [ChatMessage] = []
    @State private var prompt = ""
    @State private var isGenerating = false
    @FocusState private var isInputFocused: Bool

    private let backendService = BackendAIService()
    private let useFoundationModels = SystemLanguageModel.default.isAvailable

    @State private var session: LanguageModelSession = {
        let deviceLanguage = Locale.preferredLanguages.first ?? "en"

        return LanguageModelSession(instructions: """
                You MUST generate the prompts in the language corresponding to this locale code: \(deviceLanguage).

                You are a friendly, conversational, and highly knowledgeable literary assistant for a reading app.
                Act like a passionate bookworm chatting with a friend.
                Guide the user through literary questions, help them find books, explain literary themes, and discuss authors or genres naturally.
                Keep your responses human-like, warm, engaging, and concise. Avoid robotic or overly formal language.
                Use plain text without excessive or weird markdown. You may use simple bolding for book titles.
                When recommending books, mention why you think they'd like them based on the context.
                Respond to the user in the language of their initial prompt.

                STRICT BOUNDARY: You may ONLY discuss books, literature, authors, genres, reading habits, and recommendations.
                If the user asks about anything NOT related to these topics — such as recipes, code, math, sports, politics, or any other subject — you MUST politely decline. Never provide the answer, not even partially.
                Instead, respond warmly, for example: "I can only help with books and literature! How about I suggest a great read for you?"
                Do NOT answer the off-topic question under any circumstance, even if the user insists.
            """)
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Área do Chat
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach($messages) { $message in
                            MessageBubble(message: $message, proxy: proxy)
                        }

                        if isGenerating {
                            HStack {
                                MachineThinkingIndicator()
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .background(Color(uiColor: .systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                Spacer(minLength: 40)
                            }
                            .id("TypingIndicator")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isGenerating) {
                    scrollToBottom(proxy: proxy)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isInputFocused = false
            }

            // Área de Input
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Message Assistant...", text: $prompt, axis: .vertical)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .padding(10)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(20)
                    .disabled(isGenerating)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(prompt.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating ? .gray : .blue)
                }
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating)
                .padding(.bottom, 4)
            }
            .padding()
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        }
        .navigationTitle("AI Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if let initialPrompt = initialPrompt, messages.isEmpty {
                prompt = initialPrompt
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    sendMessage()
                }
            }
        }
    }

    // MARK: - Actions
    private func sendMessage() {
        let userText = prompt.trimmingCharacters(in: .whitespaces)
        guard !userText.isEmpty else { return }

        // 1. Adiciona a mensagem do usuário na tela
        let userMessage = ChatMessage(text: userText, role: .user)
        messages.append(userMessage)

        // 2. Limpa o input e bloqueia envio de novas mensagens
        prompt = ""
        isGenerating = true

        // 3. Tenta Foundation Models primeiro; se falhar, cai pro backend
        Task {
            do {
                var response: String?

                // Tenta on-device primeiro
                if useFoundationModels {
                    do {
                        response = try await session.respond(to: userText).content
                    } catch {
                        print("Foundation Models falhou, usando backend: \(error)")
                    }
                }

                // Fallback: backend (Groq/Llama)
                if response == nil {
                    response = try await backendService.chat(message: userText)
                }

                await MainActor.run {
                    messages.append(ChatMessage(text: response ?? "No response.", role: .assistant, isAnimating: true))
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", role: .assistant))
                    isGenerating = false
                }
            }
        }
    }

    private func handleGenerationError(_ error: LanguageModelSession.GenerationError) {
        let errorMessage: String
        switch error {
        case .guardrailViolation:
            errorMessage = "Guardrail Violation: \(error.localizedDescription)"
        case .decodingFailure:
            errorMessage = "Decoding Failure: \(error.localizedDescription)"
        case .rateLimited:
            errorMessage = "Rate limit exceeded: \(error.localizedDescription)"
        default:
            errorMessage = "Generation Error: \(error.localizedDescription)"
        }

        messages.append(ChatMessage(text: errorMessage, role: .assistant))
        print(errorMessage)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if isGenerating {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("TypingIndicator", anchor: .bottom)
            }
        } else if let lastMessageId = messages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastMessageId, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble Component
struct MessageBubble: View {
    @Binding var message: ChatMessage
    var proxy: ScrollViewProxy? = nil
    @State private var displayedText: String = ""

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
            }

            Text(message.isAnimating ? displayedText : message.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.role == .user ? Color.blue : Color(uiColor: .systemGray5))
                .foregroundColor(message.role == .user ? .white : Color(uiColor: .label))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .task {
                    if message.isAnimating {
                        await typeWriter()
                    }
                }

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
    }

    private func typeWriter() async {
        let characters = Array(message.text)
        var currentText = ""
        for char in characters {
            if Task.isCancelled { break }
            currentText.append(char)
            displayedText = currentText

            await MainActor.run {
                proxy?.scrollTo(message.id, anchor: .bottom)
            }

            try? await Task.sleep(nanoseconds: 15_000_000)
        }
        await MainActor.run {
            message.isAnimating = false
        }
    }
}

// MARK: - Machine Thinking Indicator Component
struct MachineThinkingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.purple)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .opacity(animating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

#Preview {
    NavigationStack {
        AIChatView()
    }
}
