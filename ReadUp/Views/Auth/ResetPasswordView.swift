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
                Text("Reset password")
                    .font(.system(size: 30, weight: .bold))
                    .padding(.top, 24)

                Text("We sent a code to \(email). Enter it below with your new password.")
                    .font(.subheadline)
                    .foregroundStyle(.secundaryLabel)
                    .multilineTextAlignment(.center)

                Label("Don't see it? Check your spam folder.", systemImage: "exclamationmark.bubble")
                    .font(.footnote)
                    .foregroundStyle(.secundaryLabel)
                    .multilineTextAlignment(.center)

                AuthTextField(
                    placeholder: "6-digit code",
                    text: $code,
                    systemImage: "number",
                    keyboardType: .numberPad
                )
                .padding(.top, 8)
                .onChange(of: code) {
                    // Limita a 6 dígitos numéricos.
                    code = String(code.filter(\.isNumber).prefix(6))
                }

                AuthSecureField(placeholder: "New password", text: $newPassword,
                                textContentType: .newPassword)

                AuthSecureField(placeholder: "Confirm new password", text: $confirmPassword,
                                textContentType: .newPassword)

                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords don't match.")
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
                    title: "Reset password",
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
        .navigationTitle("Reset password")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authManager.errorMessage = nil }
        .alert("Password updated", isPresented: $didReset) {
            Button("Back to login") { dismiss() }
        } message: {
            Text("Your password has been reset. Sign in with your new password.")
        }
    }
}

#Preview {
    NavigationStack {
        ResetPasswordView(email: "test@readup.com")
            .environment(AuthManager())
    }
}
