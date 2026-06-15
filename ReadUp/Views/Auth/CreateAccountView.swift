import SwiftUI

struct CreateAccountView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var acceptedTerms = false
    @State private var showTerms = false

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && passwordsMatch && acceptedTerms
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(Localization.Auth.createAccount.string)
                    .font(.system(size: 30, weight: .bold))
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                AuthTextField(placeholder: Localization.Auth.name.string, text: $name,
                              textContentType: .givenName, autocapitalization: .words)

                AuthTextField(placeholder: Localization.Auth.lastName.string, text: $lastName,
                              textContentType: .familyName, autocapitalization: .words)

                AuthTextField(placeholder: Localization.Auth.email.string, text: $email,
                              keyboardType: .emailAddress, textContentType: .emailAddress)

                AuthSecureField(placeholder: Localization.Auth.password.string, text: $password,
                                textContentType: .newPassword)

                AuthSecureField(placeholder: Localization.Auth.confirmPassword.string, text: $confirmPassword,
                                textContentType: .newPassword)

                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text(Localization.Auth.passwordsMismatch.string)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Button {
                        showTerms = true
                    } label: {
                        Text(Localization.Auth.acceptTerms.string)
                            .font(.subheadline)
                            .foregroundStyle(Color(uiColor: .label))
                            .underline()
                    }
                    Spacer()
                    Toggle("", isOn: $acceptedTerms)
                        .labelsHidden()
                        .tint(.emphasis)
                }
                .padding(.top, 4)

                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                AuthPrimaryButton(
                    title: Localization.Auth.createAccount.string,
                    isLoading: authManager.isLoading,
                    isEnabled: isFormValid
                ) {
                    let fullName = [name, lastName]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    Task { await authManager.signUp(name: fullName, email: email, password: password) }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(.backgroundPrimary)
        .navigationTitle(Localization.Auth.createAccount.string)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authManager.errorMessage = nil }
        .sheet(isPresented: $showTerms) {
            TermsView()
        }
    }
}

fileprivate struct TermsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(Localization.Auth.termsTitle.string)
                        .font(.title2.bold())
                    
                    Text(Localization.Auth.termsBody.string)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(Localization.Auth.termsTitle.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Localization.Generic.done.string) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateAccountView()
            .environment(AuthManager())
    }
}
