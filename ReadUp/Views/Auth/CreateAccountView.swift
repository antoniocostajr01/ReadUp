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
                Text("Create Account")
                    .font(.system(size: 30, weight: .bold))
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                AuthTextField(placeholder: "Name", text: $name,
                              textContentType: .givenName, autocapitalization: .words)

                AuthTextField(placeholder: "Last name", text: $lastName,
                              textContentType: .familyName, autocapitalization: .words)

                AuthTextField(placeholder: "Email", text: $email,
                              keyboardType: .emailAddress, textContentType: .emailAddress)

                AuthSecureField(placeholder: "Password", text: $password,
                                textContentType: .newPassword)

                AuthSecureField(placeholder: "Confirm password", text: $confirmPassword,
                                textContentType: .newPassword)

                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords don't match.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Button {
                        showTerms = true
                    } label: {
                        Text("I accept the terms and privacy policy")
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
                    title: "Create Account",
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
        .navigationTitle("Create Account")
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
                    Text("Terms of Service & Privacy Policy")
                        .font(.title2.bold())
                    
                    Text("""
                        By creating an account on ReadUp, you agree to the following terms:
                        
                        1. Data Collection: We collect the books you search and save, to provide a personalized reading experience.
                        
                        2. AI Assistant: The AI recommendations are generated based on your reading preferences. Responses may occasionally be inaccurate.
                        
                        3. Privacy: We do not sell your personal data to third parties. Your reading data is yours.
                        
                        4. Usage: You agree not to misuse our services or help anyone else do so.
                        
                        (These are generic placeholder terms for demonstration purposes.)
                        """)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
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
