import SwiftUI

/// Introdução multi-página mostrada antes do login (carrossel com dots).
struct WelcomeView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var currentPage = 0
    @State private var navigateToLogin = false

    private let pages = OnboardingPage.all

    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if currentPage > 0 {
                    Button(Localization.Generic.back.string) { withAnimation { currentPage -= 1 } }
                        .foregroundStyle(.brand)
                }
                Spacer()
                Button(Localization.Generic.skip.string) { withAnimation { currentPage = pages.count - 1 } }
                    .foregroundStyle(.brand)
            }
            .font(.body.weight(.medium))
            .padding(.horizontal, 20)
            .padding(.top, Spacing.sm)
            .opacity(currentPage == pages.count - 1 ? 0 : 1)

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Dots
            HStack(spacing: Spacing.sm) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.brand : Color.inkMuted.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, Spacing.xl)

            Button {
                if !isLastPage {
                    withAnimation { currentPage += 1 }
                } else {
                    authManager.enterGuestMode()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text(isLastPage ? Localization.Onboarding.getStarted.string : Localization.Onboarding.next.string)
                    if !isLastPage {
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.headingRow)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.brand)
                )
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, isLastPage ? 8 : 16)

            // Na última página, oferece o login pra quem já tem conta.
            Button(Localization.Onboarding.alreadyHaveAccount.string) {
                navigateToLogin = true
            }
            .font(.bodySupportingStrong)
            .foregroundStyle(.brand)
            .padding(.bottom, Spacing.lg)
            .opacity(isLastPage ? 1 : 0)
            .disabled(!isLastPage)
        }
        .background(.surface)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToLogin) {
            LoginView()
        }
    }
}

// MARK: - Conteúdo das páginas

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let kind: Kind

    enum Kind { case logo, covers, assistant }

    static let all: [OnboardingPage] = [
        .init(title: "ReadUp",
              subtitle: Localization.Onboarding.page1Subtitle.string,
              kind: .logo),
        .init(title: "",
              subtitle: Localization.Onboarding.page2Subtitle.string,
              kind: .covers),
        .init(title: Localization.Onboarding.page3Title.string,
              subtitle: Localization.Onboarding.page3Subtitle.string,
              kind: .assistant),
    ]
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            illustration
                .padding(.bottom, Spacing.xl)
            VStack(spacing: Spacing.md) {
                if !page.title.isEmpty {
                    Text(page.title)
                        .font(.titleScreenLarge)
                        .multilineTextAlignment(.center)
                }
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundStyle(page.kind == .logo ? .inkMuted : Color.ink)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.xxl)
            Spacer()
        }
    }
    
    @ViewBuilder
    private var illustration: some View {
        switch page.kind {
        case .logo:
            Image(.readUpIcon)
                .resizable()
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                .background {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.accent)
                        .frame(width: 150, height: 150)
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                }
            
            
        case .covers:
            FannedCovers()
        case .assistant:
            Image(systemName: "sparkles")
                .font(.system(size: 88, weight: .regular))
                .foregroundStyle(.brand)
        }
    }
}

/// Capas de livros reais usadas no onboarding
private struct FannedCovers: View {
    private let books = ["hoobitbook", "stevejobsBook", "1984book", "homodeusbook"]
    @State private var isVisible = false

    var body: some View {
        ZStack {
            ForEach(Array(books.enumerated()), id: \.offset) { index, book in
                Image(book)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 4, y: 3)
                    .zIndex(Double(books.count - index))
                    .offset(x: isVisible ? CGFloat(index) * 55 - 82.5 : CGFloat(index) * 55 - 82.5 - 40)
                    .opacity(isVisible ? 1 : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7)
                        .delay(Double(index) * 0.15),
                        value: isVisible
                    )
            }
        }
        .frame(height: 200)
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
            .environment(AuthManager())
    }
}
