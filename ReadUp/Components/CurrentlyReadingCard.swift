import SwiftUI

/// O herói do Home: a capa sangrando na largura toda, escurecida por um scrim, com
/// título, autor·página e a barra de progresso por cima. Figma `13:15`.
///
/// A capa é a única coisa na tela que carrega sombra — aqui ela é a própria arte, e
/// o texto só é legível por causa do scrim, não de um card por baixo.
struct CurrentlyReadingCard: View {
    let book: Book
    let progressValue: Double
    /// Capa já baixada (cache da `LibraryStore`). Se presente, é exibida direto, sem `AsyncImage`.
    var coverData: Data? = nil

    private var pageLine: String {
        let current = max(0, book.progress ?? 0)
        return "\(book.author) · " + String(
            format: Localization.Components.pageOf.string, current, book.numberOfPages
        )
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            cover
                .frame(maxWidth: .infinity)
                .frame(height: Spacing.heroHeight)
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
                Text(book.title)
                    .textStyle(.titlePrimary)
                    .foregroundStyle(Palette.inkOnArt)
                    .lineLimit(2)

                Text(pageLine)
                    .textStyle(.label)
                    .foregroundStyle(Palette.inkOnArt.opacity(0.72))
                    .lineLimit(1)

                ProgressTrackOnArt(value: progressValue)
            }
            .padding(.horizontal, Spacing.gutterList)
            .padding(.bottom, Spacing.gutterList)
        }
        .frame(height: Spacing.heroHeight)
        .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
    }

    /// Mostra a capa do cache (estável) ou cai no `AsyncImage` se ainda não baixada.
    @ViewBuilder
    private var cover: some View {
        if let coverData, let image = UIImage(data: coverData) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            AsyncImage(url: book.coverUrl.flatMap(URL.init(string:))) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Palette.surfaceSunken
                }
            }
        }
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
