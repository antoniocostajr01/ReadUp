import SwiftUI

/// Uma sessão na lista do Home. Figma `14:23`.
///
/// Sem card: as linhas ficam direto na página, separadas por uma régua fina. A
/// contagem de páginas é serifada, como todo número no app.
struct RecentActivityRow: View {
    let session: LiterarySession
    let formattedDate: String

    var body: some View {
        HStack(spacing: Spacing.cardInset) {
            BookCoverView(
                coverUrl: session.book.coverUrl,
                width: Spacing.coverRowWidth,
                height: Spacing.coverRowHeight,
                cornerRadius: Radius.coverSm
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(session.book.title)
                    .textStyle(.bodyDefault)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                Text(formattedDate)
                    .textStyle(.captionDefault)
                    .foregroundStyle(Palette.inkMeta)
                    .lineLimit(1)
            }

            Spacer(minLength: Spacing.sm)

            Text("+\(session.pagesRead)")
                .textStyle(.titleTertiary)
                .foregroundStyle(Palette.ink)
        }
        .padding(.vertical, 10)
    }
}
