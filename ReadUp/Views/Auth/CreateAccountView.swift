import SwiftUI

struct CreateAccountView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
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
        GeometryReader { proxy in
            ScrollView {
                content(minHeight: proxy.size.height)
            }
        }
        .background(Color.surface.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authManager.errorMessage = nil }
        .sheet(isPresented: $showTerms) {
            TermsView()
        }
    }

    /// Conteúdo rolável com o bloco inferior (promessa + botão) fixado ao fundo
    /// via `minHeight` do próprio `GeometryReader` — evita depender de `UIScreen`.
    private func content(minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
                // Título de duas linhas, igual ao frame do Figma.
                VStack(alignment: .leading, spacing: 0) {
                    Text(Localization.Auth.createAccountLine1.string)
                    Text(Localization.Auth.createAccountLine2.string)
                }
                .textStyle(.titleXL)
                .foregroundStyle(.ink)
                .padding(.top, Spacing.md)

                VStack(spacing: Spacing.lg) {
                    UnderlinedField(
                        label: Localization.Auth.name.string,
                        text: $name,
                        placeholder: Localization.Auth.placeholderName.string,
                        textContentType: .name,
                        autocapitalization: .words
                    )

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
                        textContentType: .newPassword
                    )

                    UnderlinedField(
                        label: Localization.Auth.confirmPassword.string,
                        text: $confirmPassword,
                        isSecure: true,
                        textContentType: .newPassword
                    )
                }

                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text(Localization.Auth.passwordsMismatch.string)
                        .textStyle(.captionDefault)
                        .foregroundStyle(.danger)
                }

                termsRow

                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .textStyle(.captionDefault)
                        .foregroundStyle(.danger)
                }

                Spacer(minLength: Spacing.xl)

                bottomBlock
            }
        .padding(.horizontal, Spacing.gutterAuth)
        .padding(.bottom, 30)
        .frame(minHeight: minHeight, alignment: .top)
    }

    /// Linha de aceite dos termos: checkbox custom (SF Symbol, sem Toggle colorido).
    /// Tocar no rótulo sublinhado abre o sheet; tocar no resto da linha alterna o aceite.
    private var termsRow: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                acceptedTerms.toggle()
            } label: {
                Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                    .foregroundStyle(.ink)
            }
            .buttonStyle(.plain)

            Button {
                showTerms = true
            } label: {
                Text(Localization.Auth.acceptTerms.string)
                    .textStyle(.bodySupporting)
                    .foregroundStyle(.ink)
                    .underline()
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            acceptedTerms.toggle()
        }
    }

    private var bottomBlock: some View {
        VStack(spacing: Spacing.sm) {
            Text(Localization.Auth.crossDevicePromise.string)
                .textStyle(.captionFine)
                .foregroundStyle(.inkMeta)
                .frame(maxWidth: .infinity, alignment: .leading)

            ReadUpButton(
                title: Localization.Auth.createAccount.string,
                isLoading: authManager.isLoading,
                isEnabled: isFormValid
            ) {
                Task { await authManager.signUp(name: name, email: email, password: password) }
            }
        }
    }
}

fileprivate struct TermsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(Localization.Auth.termsTitle.string)
                        .textStyle(.titleSecondary)
                        .foregroundStyle(.ink)

                    Text(Localization.Auth.termsBody.string)
                        .textStyle(.bodyDefault)
                        .foregroundStyle(.inkMuted)
                }
                .padding(Spacing.gutterAuth)
            }
            .background(.surface)
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
