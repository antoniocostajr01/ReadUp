import SwiftUI

/// Uma capa numa prateleira da Library. Figma `41:1033`.
///
/// A sombra é intencional: capa de livro é objeto empilhado, uma das duas coisas no
/// sistema que ainda projetam sombra. A barra de progresso só aparece em "Lendo".
struct ShelfCover: View {
    let book: Book
    /// Progresso de 0 a 1. `nil` esconde a barra — só a prateleira "Lendo" a mostra.
    var progress: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            AsyncImage(url: book.coverUrl.flatMap(URL.init(string:))) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Palette.surfaceSunken
                }
            }
            .frame(width: Spacing.coverShelfWidth, height: Spacing.coverShelfHeight)
            .clipShape(RoundedRectangle(cornerRadius: Radius.cover, style: .continuous))
            .coverShadow(.coverSm)

            if let progress {
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.dividerStrong)
                    Capsule()
                        .fill(Palette.ink)
                        .frame(width: Spacing.coverShelfWidth * min(max(progress, 0), 1))
                }
                .frame(width: Spacing.coverShelfWidth, height: Spacing.progressBarHeight)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(book.title), \(book.author)")
    }
}
