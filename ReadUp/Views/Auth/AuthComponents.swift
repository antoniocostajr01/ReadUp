import SwiftUI

/// Campo de texto padrão das telas de autenticação (com ícone opcional à esquerda).
struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var systemImage: String? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.secundaryLabel)
            }
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
            
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.secundaryLabel.opacity(0.3), lineWidth: 0.5)
        )
    }
}

/// Campo de senha com botão de mostrar/ocultar (ícone de olho) e cadeado à esquerda.
struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    var textContentType: UITextContentType? = nil

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .foregroundStyle(.secundaryLabel)
            
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(textContentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(.secundaryLabel)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        // Adicionada a borda leve
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.secundaryLabel.opacity(0.3), lineWidth: 0.5)
        )
    }
}

/// Botão primário verde (estilo "Sign in" / "Create Account" do Figma).
struct AuthPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isEnabled ? Color.emphasis : Color.secundaryLabel)
            )
        }
        .disabled(!isEnabled || isLoading)
    }
}
