import SwiftUI
import AuthenticationServices

/// Tela de login — Editorial Cream. Figma `26:92`.
struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var appleSignIn = AppleSignInCoordinator()

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text(Localization.Auth.welcomeBack.string)
                .textStyle(.titleXL)
                .foregroundStyle(.ink)

            VStack(spacing: 22) {
                UnderlinedField(
                    label: Localization.Auth.email.string,
                    text: $email,
                    placeholder: Localization.Auth.placeholderEmail.string,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )

                UnderlinedField(
                    label: Localization.Auth.password.string,
                    text: $password,
                    placeholder: Localization.Auth.placeholderPassword.string,
                    isSecure: true,
                    textContentType: .password
                )
            }

            NavigationLink(Localization.Auth.forgotPasswordLink.string) {
                ForgotPasswordView()
            }
            .textStyle(.label)
            .foregroundStyle(.inkMeta)

            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .textStyle(.captionDefault)
                    .foregroundStyle(.danger)
            }

            Spacer()

            VStack(spacing: 10) {
                ReadUpButton(
                    title: Localization.Auth.signIn.string,
                    variant: .primary,
                    isLoading: authManager.isLoading,
                    isEnabled: isFormValid
                ) {
                    Task { await authManager.signIn(email: email, password: password) }
                }

                appleSignInButton

                HStack(spacing: 4) {
                    Spacer()
                    Text(Localization.Auth.newHere.string)
                        .textStyle(.label)
                        .foregroundStyle(.inkMeta)
                    NavigationLink(Localization.Auth.createAccount.string) {
                        CreateAccountView()
                    }
                    .textStyle(.label)
                    .foregroundStyle(.ink)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, Spacing.gutterAuth)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // O `ignoresSafeArea` fica só no fundo, senão o conteúdo sobe pro notch.
        .background(Color.surface.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authManager.errorMessage = nil }
    }

    /// "Continue with Apple" é um `ReadUpButton(.secondary)` de verdade: o fluxo da
    /// Apple é disparado direto pelo `AppleSignInCoordinator`, sem o botão nativo
    /// escondido por baixo (que vazava por trás do nosso).
    private var appleSignInButton: some View {
        ReadUpButton(title: Localization.Auth.continueWithApple.string, variant: .secondary) {
            appleSignIn.start { result in
                Task { await authManager.signInWithApple(result: result) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(AuthManager())
    }
}
