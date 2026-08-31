import SwiftUI

/// O seletor de status do livro. Figma `47:1842` (detalhe) e `47:1795` (entrada manual).
///
/// Pílula de largura total, contorno de 1pt em `line/border-strong`: rótulo em
/// overline à esquerda, valor serifado e o chevron à direita. É o mesmo controlo no
/// detalhe do livro, na entrada manual e na folha do scanner.
struct StatusPill: View {
    /// `nil` enquanto nada foi escolhido — o rótulo vira "Select status".
    @Binding var status: BookStatus?

    var body: some View {
        Menu {
            ForEach(BookStatus.allCases, id: \.self) { option in
                Button(option.displayName) { status = option }
            }
        } label: {
            HStack {
                Text((status == nil
                      ? Localization.BookDetails.selectStatus.string
                      : Localization.BookDetails.statusLabel.string).uppercased())
                    .textStyle(.overline)
                    .foregroundStyle(Palette.inkFaint)

                Spacer()

                HStack(spacing: 9) {
                    if let status {
                        Text(status.displayName)
                            .textStyle(.valueStatus)
                    }
                    Image(systemName: "chevron.down")
                        .font(.iconLabel)
                }
                .foregroundStyle(Palette.ink)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 15)
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Palette.borderStrong, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var a: BookStatus? = .reading
    @Previewable @State var b: BookStatus? = nil

    VStack(spacing: Spacing.md) {
        StatusPill(status: $a)
        StatusPill(status: $b)
    }
    .padding(Spacing.gutterDetail)
    .background(Palette.surface)
}
