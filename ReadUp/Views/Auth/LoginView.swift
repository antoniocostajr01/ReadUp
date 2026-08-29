import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        ZStack {
            // Garante que o fundo ocupe a tela toda, ignorando as margens seguras (notch/bateria)
            Color.surface
                .ignoresSafeArea()

            VStack {
                VStack(spacing: 20) {
                    Text(Localization.Auth.loginTitle.string)
                        .font(.titleScreenLarge)
                        .padding(.top, 40)
                        .padding(.bottom, Spacing.md)

                    AuthTextField(
                        placeholder: Localization.Auth.email.string,
                        text: $email,
                        systemImage: "envelope.fill",
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )

                    AuthSecureField(
                        placeholder: Localization.Auth.password.string,
                        text: $password,
                        textContentType: .password
                    )
                    
                    HStack {
                        Spacer()
                        NavigationLink(Localization.Auth.forgotPassword.string) {
                            ForgotPasswordView()
                        }
                        .font(.bodySupportingStrong)
                        .foregroundStyle(.brand)
                    }

                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.captionDefault)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    AuthPrimaryButton(
                        title: Localization.Auth.signIn.string,
                        isLoading: authManager.isLoading,
                        isEnabled: isFormValid
                    ) {
                        Task { await authManager.signIn(email: email, password: password) }
                    }
                    .padding(.top, Spacing.sm)

                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await authManager.signInWithApple(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    
                    HStack {
                        Rectangle().fill(.inkMuted.opacity(0.3)).frame(height: 1)
                        Text(Localization.Generic.or.string).font(.bodySupporting).foregroundStyle(.inkMuted)
                        Rectangle().fill(.inkMuted.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.vertical, Spacing.xs)

                    NavigationLink {
                        CreateAccountView()
                    } label: {
                        Text(Localization.Auth.createAccount.string)
                            .font(.headingRow)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                                    .fill(Color.black)
                            )
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authManager.errorMessage = nil }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(AuthManager())
    }
}
