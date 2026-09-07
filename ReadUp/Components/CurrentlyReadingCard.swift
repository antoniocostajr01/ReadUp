import SwiftUI

/// O herói do Home: a capa sangrando na largura toda, escurecida por um scrim, com
/// título, autor·página e a barra de progresso por cima. Figma `13:15`.
///
/// A capa é a única coisa na tela que carrega sombra — aqui ela é a própria arte, e
/// o texto só é legível por causa do scrim, não de um card por baixo.
struct CurrentlyReadingCard: View {
    let book: Book
    let progressValue: Double
    /// `nil` = sangra na largura toda (o herói original). Com um valor, vira um card do
    /// carrossel do Home.
    var width: CGFloat? = nil
    var height: CGFloat = Spacing.heroHeight

    private var pageLine: String {
        let current = max(0, book.progress ?? 0)
        return "\(book.author) · " + String(
            format: Localization.Components.pageOf.string, current, book.numberOfPages
        )
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Sem capa, cai no placeholder tipográfico do `BookCoverView` — é ele que os
            // cards "S" e "O" do Figma mostram, não um preenchimento chapado.
            CoverImage(url: book.coverUrl.flatMap(URL.init(string:))) {
                BookCoverView(
                    coverUrl: nil,
                    width: width ?? Spacing.readingCardWidth,
                    height: height,
                    cornerRadius: 0,
                    title: book.title,
                    author: book.author
                )
            }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()

            // Do Figma `13:16`: escuro em cima pro status bar, transparente no meio,
            // e o peso todo embaixo pra sustentar o texto.
            LinearGradient(
                stops: [
                    .init(color: Palette.scrimTop.opacity(0.55), location: 0),
                    .init(color: Palette.scrimTop.opacity(0.22), location: 0.14),
                    .init(color: Palette.scrimBottom.opacity(0), location: 0.34),
                    .init(color: Palette.scrimBottom.opacity(0.86), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: Spacing.md) {
                // Serifada de 30 sangrando na largura toda; num card de 232 ela quebraria
                // em duas linhas no primeiro título comprido, então lá desce pra 22.
                Text(book.title)
                    .textStyle(width == nil ? .titlePrimary : .titleCard)
                    .foregroundStyle(Palette.inkOnArt)
                    .lineLimit(2)

                Text(pageLine)
                    .textStyle(width == nil ? .label : .captionDefault)
                    .foregroundStyle(Palette.inkOnArt.opacity(0.72))
                    .lineLimit(1)

                ProgressTrackOnArt(value: progressValue)
            }
            .padding(.horizontal, Spacing.gutterList)
            .padding(.bottom, Spacing.gutterList)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
    }
}

/// A barra de progresso sobre a arte: trilho em creme translúcido, preenchimento
/// âmbar. Fina de propósito — 3pt, Figma `13:20`.
private struct ProgressTrackOnArt: View {
    let value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.inkOnArt.opacity(0.28))
                Capsule()
                    .fill(Palette.accentProgress)
                    .frame(width: geometry.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: Spacing.progressBarHeight)
    }
}
