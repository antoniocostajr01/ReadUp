import SwiftUI

/// A tela de "conquista" que fecha todos os caminhos de adicionar livro — busca,
/// scanner e entrada manual. Figma `47:1603` (com capa) e `47:1588` (sem capa).
///
/// Anotação `47:1663`: *"ao ser adicionado o livro na biblioteca, o livro deve ser
/// exibido na tela e deve haver alguma animação para exibi-lo. Como se tivesse sido
/// uma conquista."* — daí a capa entrar pequena e assentar numa mola, e não aparecer
/// pronta.
///
/// Título e autor só se repetem abaixo da capa quando existe capa de verdade: no
/// placeholder tipográfico eles já estão impressos na própria capa.
struct BookAddedView: View {
    let book: Book
    /// Fechar a tela **e** o fluxo inteiro, voltando à biblioteca.
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var hasLanded = false

    private var hasCover: Bool { !(book.coverUrl?.isEmpty ?? true) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                ChromeChip(systemImage: "xmark") {
                    dismiss()
                    onClose()
                }
            }
            .frame(height: 38)

            VStack(spacing: 20) {
                BookCoverView(
                    coverUrl: book.coverUrl,
                    width: 224,
                    height: 320,
                    cornerRadius: Radius.coverLg,
                    title: book.title,
                    author: book.author
                )
                .coverShadow(.coverHero)
                .scaleEffect(hasLanded ? 1 : 0.6)
                .offset(y: hasLanded ? 0 : 28)

                if hasCover {
                    Text(book.title)
                        .textStyle(.titleBook)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)

                    Text(book.author)
                        .textStyle(.authorRow)
                        .foregroundStyle(Palette.inkSoft)
                }

                Text(Localization.BookDetails.addedToLibrary.string)
                    .textStyle(.titlePrimary)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .opacity(hasLanded ? 1 : 0)
                    .offset(y: hasLanded ? 0 : 12)
            }
            .padding(.top, 48)
            .frame(maxWidth: .infinity)

            Spacer(minLength: Spacing.xl)

            ReadUpButton(title: Localization.BookDetails.addAnotherBook.string, variant: .tertiary) {
                dismiss()
            }
            .padding(.vertical, Spacing.md)
        }
        .padding(.horizontal, Spacing.gutterDetail)
        .padding(.top, 10)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .sensoryFeedback(.success, trigger: hasLanded)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { hasLanded = true }
        }
    }
}

#Preview {
    BookAddedView(
        book: Book(
            id: "1", title: "O Cortiço", author: "Aluísio Azevedo",
            numberOfPages: 304, details: "", coverUrl: nil, status: .iWantToRead
        ),
        onClose: {}
    )
}
