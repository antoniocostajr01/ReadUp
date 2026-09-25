import SwiftUI

/// Uma sessão numa lista. Figma `14:23` (Home) e `21:82` (History).
///
/// Sem card: as linhas ficam direto na página, separadas por uma régua fina. A
/// contagem de páginas é serifada, como todo número no app.
///
/// As duas telas usam a mesma linha em tamanhos diferentes — no History a capa sobe
/// para 44×64 e o delta ganha a legenda "pages" por baixo. São parâmetros e não um
/// segundo componente: os pixels são os do Figma nas duas, e só há uma linha para
/// manter.
struct RecentActivityRow: View {
    let session: LiterarySession
    let formattedDate: String
    var coverWidth: CGFloat = Spacing.coverRowWidth
    var coverHeight: CGFloat = Spacing.coverRowHeight
    var titleStyle: TypeRole = .bodyDefault
    var showsPagesCaption: Bool = false

    var body: some View {
        HStack(spacing: Spacing.cardInset) {
            BookCoverView(
                coverUrl: session.book.coverUrl,
                width: coverWidth,
                height: coverHeight,
                cornerRadius: Radius.coverSm,
                title: session.book.title,
                author: session.book.author
            )

            VStack(alignment: .leading, spacing: 2) {
                // Duas linhas: títulos longos cortados em uma viravam só o começo
                // do nome, e o livro deixava de ser reconhecível na lista.
                Text(session.book.title)
                    .textStyle(titleStyle)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(formattedDate)
                    .textStyle(.captionDefault)
                    .foregroundStyle(Palette.inkMeta)
                    .lineLimit(1)
            }

            Spacer(minLength: Spacing.sm)

            VStack(alignment: .trailing, spacing: 0) {
                Text(verbatim: "+\(session.pagesRead)")
                    .textStyle(showsPagesCaption ? .valueStatus : .titleTertiary)
                    .foregroundStyle(Palette.ink)

                if showsPagesCaption {
                    Text(Localization.Components.pages(session.pagesRead))
                        .textStyle(.overline)
                        .foregroundStyle(Palette.inkFaint)
                }
            }
            // O contador nunca encolhe: quem quebra linha é o título.
            .fixedSize()
        }
        .padding(.vertical, 10)
    }
}
