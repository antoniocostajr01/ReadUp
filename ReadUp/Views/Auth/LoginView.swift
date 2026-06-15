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
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack {
                VStack(spacing: 20) {
                    Text(Localization.Auth.loginTitle.string)
                        .font(.system(size: 34, weight: .bold))
                        .padding(.top, 40)
                        .padding(.bottom, 12)

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
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.emphasis)
                    }

                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
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
                    .padding(.top, 8)

                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await authManager.signInWithApple(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    HStack {
                        Rectangle().fill(.secundaryLabel.opacity(0.3)).frame(height: 1)
                        Text(Localization.Generic.or.string).font(.subheadline).foregroundStyle(.secundaryLabel)
                        Rectangle().fill(.secundaryLabel.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.vertical, 4)

                    NavigationLink {
                        CreateAccountView()
                    } label: {
                        Text(Localization.Auth.createAccount.string)
                            .font(.system(.headline, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.black)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
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
