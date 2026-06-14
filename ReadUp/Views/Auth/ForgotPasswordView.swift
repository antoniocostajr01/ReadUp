import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var navigateToReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Forgot password")
                    .font(.system(size: 30, weight: .bold))
                    .padding(.top, 24)

                Text("Enter your email and we'll send you a 6-digit code to reset your password.")
                    .font(.subheadline)
                    .foregroundStyle(.secundaryLabel)
                    .multilineTextAlignment(.center)

                AuthTextField(
                    placeholder: "Email",
                    text: $email,
                    systemImage: "envelope.fill",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
                .padding(.top, 8)

                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                AuthPrimaryButton(
                    title: "Send code",
                    isLoading: authManager.isLoading,
                    isEnabled: !email.isEmpty
                ) {
                    Task {
                        if await authManager.requestPasswordReset(email: email) {
                            navigateToReset = true
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
        .background(.backgroundPrimary)
        .navigationTitle("Forgot password")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authManager.errorMessage = nil }
        .navigationDestination(isPresented: $navigateToReset) {
            ResetPasswordView(email: email)
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environment(AuthManager())
    }
}
