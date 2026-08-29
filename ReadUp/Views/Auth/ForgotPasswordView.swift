import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var navigateToReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(Localization.Auth.forgotPasswordTitle.string)
                    .font(.titleScreen)
                    .padding(.top, Spacing.xl)

                Text(Localization.Auth.forgotPasswordDescription.string)
                    .font(.bodySupporting)
                    .foregroundStyle(.inkMuted)
                    .multilineTextAlignment(.center)

                AuthTextField(
                    placeholder: Localization.Auth.email.string,
                    text: $email,
                    systemImage: "envelope.fill",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
                .padding(.top, Spacing.sm)

                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.captionDefault)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                AuthPrimaryButton(
                    title: Localization.Auth.sendCode.string,
                    isLoading: authManager.isLoading,
                    isEnabled: !email.isEmpty
                ) {
                    Task {
                        if await authManager.requestPasswordReset(email: email) {
                            navigateToReset = true
                        }
                    }
                }
                .padding(.top, Spacing.sm)
            }
            .padding(.horizontal, Spacing.xl)
        }
        .background(.surface)
        .navigationTitle(Localization.Auth.forgotPasswordTitle.string)
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
