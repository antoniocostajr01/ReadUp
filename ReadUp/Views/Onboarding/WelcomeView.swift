import SwiftUI

/// Tela de boas-vindas — ponto de entrada único do fluxo de auth.
///
/// Figma `24:82` (Editorial Cream). Estática, sem carrossel: três capas
/// "espalhadas" no topo, headline serifada, corpo em sans e as três ações
/// possíveis (criar conta, entrar, continuar como visitante) presas ao fundo.
struct WelcomeView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var navigateToCreateAccount = false
    @State private var navigateToLogin = false
    @State private var coversSettled = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            coverStage
                .padding(.top, Spacing.md)

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("\(Localization.Onboarding.heroLine1.string)\n\(Localization.Onboarding.heroLine2.string)\n\(Localization.Onboarding.heroLine3.string)")
                    .textStyle(.displayHero)
                    .foregroundStyle(.ink)

                Text(Localization.Onboarding.welcomeBody.string)
                    .textStyle(.bodyDefault)
                    .foregroundStyle(.inkStrongMuted)
            }

            Spacer()

            VStack(spacing: Spacing.sm) {
                ReadUpButton(title: Localization.Onboarding.getStarted.string, variant: .primary) {
                    navigateToCreateAccount = true
                }
                ReadUpButton(title: Localization.Onboarding.alreadyHaveAccount.string, variant: .tertiary) {
                    navigateToLogin = true
                }
                // Único ponto de entrada do modo visitante — não remover.
                ReadUpButton(title: Localization.Onboarding.continueAsGuest.string, variant: .tertiary) {
                    authManager.enterGuestMode()
                }
            }
        }
        .padding(.horizontal, Spacing.gutterAuth)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // O `ignoresSafeArea` fica só no fundo: o creme sangra até as bordas, mas o
        // conteúdo continua respeitando o notch. Aplicado na view inteira, as capas
        // passavam por baixo da Dynamic Island.
        .background(Color.surface.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToCreateAccount) {
            CreateAccountView()
        }
        .navigationDestination(isPresented: $navigateToLogin) {
            LoginView()
        }
        .onAppear {
            withAnimation(Motion.easeStandard) {
                coversSettled = true
            }
        }
    }

    /// Palco das três capas, sobrepostas e levemente rotacionadas.
    private var coverStage: some View {
        ZStack {
            cover("1984book", width: 104, shadow: .coverLg)
                .rotationEffect(.degrees(-8))
                .offset(x: -100, y: 26)

            cover("homodeusbook", width: 104, shadow: .coverLg)
                .rotationEffect(.degrees(9))
                .offset(x: 100, y: 34)

            cover("stevejobsBook", width: 124, shadow: .coverStack)
                .offset(y: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .opacity(coversSettled ? 1 : 0)
        .offset(y: coversSettled ? 0 : 12)
    }

    private func cover(_ name: String, width: CGFloat, shadow: Elevation) -> some View {
        Image(name)
            .resizable()
            .aspectRatio(2 / 3, contentMode: .fill)
            .frame(width: width, height: width * 3 / 2)
            .clipShape(RoundedRectangle(cornerRadius: Radius.coverLg, style: .continuous))
            .coverShadow(shadow)
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
            .environment(AuthManager())
    }
}
