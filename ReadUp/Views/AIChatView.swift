//
//  AIChatView.swift
//  ReadUp
//
//  Created by Antonio Costa on 26/05/26.
//

import SwiftUI

struct AIChatView: View {
    var initialPrompt: String?

    init(initialPrompt: String? = nil) {
        self.initialPrompt = initialPrompt
    }

    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = LiteraryAssistantViewModel()
    @State private var showAuth = false
    private let booksService = GoogleBooksService()
    @FocusState private var isInputFocused: Bool

    /// Convidado pode trocar até 3 mensagens antes de precisar criar conta.
    private let guestMessageLimit = 3

    private var guestLimitReached: Bool {
        authManager.isGuest && viewModel.userMessageCount >= guestMessageLimit
    }

    var body: some View {
        VStack(spacing: 0) {
            // Área do Chat
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            AIMessageBubble(message: message, service: booksService)
                        }

                        if viewModel.isThinking {
                            HStack {
                                MachineThinkingIndicator()
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                Spacer(minLength: 40)
                            }
                            .id("TypingIndicator")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isThinking) {
                    scrollToBottom(proxy: proxy)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isInputFocused = false
            }

            // Área de Input — ou parede de "criar conta" pro convidado.
            if guestLimitReached {
                guestLimitBar
            } else {
                inputBar
            }
        }
        .background(.backgroundPrimary)
        .navigationTitle(Localization.AI.chatTitle.string)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showAuth) {
            AuthSheet()
        }
        .onAppear {
            if let initialPrompt = initialPrompt, viewModel.messages.count <= 1 {
                viewModel.inputText = initialPrompt
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    sendMessage()
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField(Localization.AI.chatPlaceholder.string, text: $viewModel.inputText, axis: .vertical)
                .focused($isInputFocused)
                .lineLimit(1...5)
                .padding(10)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(20)
                .disabled(viewModel.isThinking)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isThinking ? .gray : .emphasis)
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isThinking)
            .padding(.bottom, 4)
        }
        .padding()
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    private var guestLimitBar: some View {
        VStack(spacing: 10) {
            Text(Localization.AI.guestLimitTitle.string)
                .font(.system(.headline, weight: .semibold))
                .multilineTextAlignment(.center)

            Text(Localization.AI.guestLimitMessage.string)
                .font(.subheadline)
                .foregroundStyle(.secundaryLabel)
                .multilineTextAlignment(.center)

            Button {
                showAuth = true
            } label: {
                Text(Localization.Auth.signInOrCreate.string)
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
        .padding()
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    // MARK: - Actions
    private func sendMessage() {
        Task {
            await viewModel.sendMessage(booksService: booksService)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if viewModel.isThinking {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("TypingIndicator", anchor: .bottom)
            }
        } else if let lastMessageId = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastMessageId, anchor: .bottom)
            }
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
                    .fill(Color.emphasis)
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
            .environment(AuthManager())
    }
}
