import SwiftUI

/// Tela cheia verde com o livro saltando e girando.
/// Mostrada enquanto o app carrega as infos do usuário (após login e em cada launch com sessão).
struct LoadingView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.accent.ignoresSafeArea()

            VStack(spacing: 28) {
                Image("ReadUpIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .scaleEffect(pulse ? 1.12 : 0.9)
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 8)

                // Mensagem de erro + retry (ex.: falha de rede no carregamento).
                if let errorMessage = authManager.errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        Button(Localization.Generic.tryAgain.string) {
                            Task { await authManager.bootstrap() }
                        }
                        .font(.headline)
                        .foregroundStyle(.emphasis)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 32)
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

#Preview {
    LoadingView()
        .environment(AuthManager())
}
