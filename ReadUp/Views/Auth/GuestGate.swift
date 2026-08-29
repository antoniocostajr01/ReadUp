//
//  GuestGate.swift
//  ReadUp
//
//  Componentes de gate de login usados no modo convidado.
//

import SwiftUI

/// Apresenta o fluxo de login/cadastro como sheet. Fecha sozinho ao autenticar.
struct AuthSheet: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LoginView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(Localization.Generic.cancel.string) { dismiss() }
                    }
                }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated { dismiss() }
        }
    }
}

/// Parede mostrada nas abas que exigem conta quando o usuário é convidado.
struct SignInRequiredView: View {
    let icon: String
    let title: String
    let message: String

    @State private var showAuth = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.brand)

            Text(title)
                .font(.titleSecondary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.bodyDefault)
                .foregroundStyle(.inkMuted)
                .multilineTextAlignment(.center)

            Button {
                showAuth = true
            } label: {
                Text(Localization.Auth.signInOrCreate.string)
                    .font(.headingRow)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                            .fill(Color.brand)
                    )
            }
            .padding(.top, Spacing.sm)
        }
        .padding(.horizontal, Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.surface)
        .sheet(isPresented: $showAuth) {
            AuthSheet()
        }
    }
}

#Preview {
    SignInRequiredView(
        icon: "books.vertical.fill",
        title: "Crie sua conta",
        message: "Crie uma conta gratuita para acompanhar sua leitura."
    )
    .environment(AuthManager())
}
