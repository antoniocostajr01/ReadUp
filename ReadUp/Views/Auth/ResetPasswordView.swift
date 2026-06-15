import SwiftUI

struct ResetPasswordView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    let email: String

    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var didReset = false

    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    private var isFormValid: Bool {
        code.count == 6 && passwordsMatch
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(Localization.Auth.resetPasswordTitle.string)
                    .font(.system(size: 30, weight: .bold))
                    .padding(.top, 24)

                Text(String(format: Localization.Auth.resetPasswordDescription.string, email))
                    .font(.subheadline)
                    .foregroundStyle(.secundaryLabel)
                    .multilineTextAlignment(.center)

                Label(Localization.Auth.spamHint.string, systemImage: "exclamationmark.bubble")
                    .font(.footnote)
                    .foregroundStyle(.secundaryLabel)
                    .multilineTextAlignment(.center)

                AuthTextField(
                    placeholder: Localization.Auth.codePlaceholder.string,
                    text: $code,
                    systemImage: "number",
                    keyboardType: .numberPad
                )
                .padding(.top, 8)
                .onChange(of: code) {
                    // Limita a 6 dígitos numéricos.
                    code = String(code.filter(\.isNumber).prefix(6))
                }

                AuthSecureField(placeholder: Localization.Auth.newPassword.string, text: $newPassword,
                                textContentType: .newPassword)

                AuthSecureField(placeholder: Localization.Auth.confirmNewPassword.string, text: $confirmPassword,
                                textContentType: .newPassword)

                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text(Localization.Auth.passwordsMismatch.string)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                AuthPrimaryButton(
                    title: Localization.Auth.resetPasswordButton.string,
                    isLoading: authManager.isLoading,
                    isEnabled: isFormValid
                ) {
                    Task {
                        if await authManager.confirmPasswordReset(
                            email: email, code: code, newPassword: newPassword
                        ) {
                            didReset = true
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
        .background(.backgroundPrimary)
        .navigationTitle(Localization.Auth.resetPasswordTitle.string)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authManager.errorMessage = nil }
        .alert(Localization.Auth.passwordUpdated.string, isPresented: $didReset) {
            Button(Localization.Auth.backToLogin.string) { dismiss() }
        } message: {
            Text(Localization.Auth.passwordResetSuccess.string)
        }
    }
}

#Preview {
    NavigationStack {
        ResetPasswordView(email: "test@readup.com")
            .environment(AuthManager())
    }
}
