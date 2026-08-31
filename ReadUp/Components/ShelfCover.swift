import SwiftUI

/// Uma capa numa prateleira da Library. Figma `41:1033`.
///
/// A sombra é intencional: capa de livro é objeto empilhado, uma das duas coisas no
/// sistema que ainda projetam sombra. A barra de progresso só aparece em "Lendo".
struct ShelfCover: View {
    let book: Book
    /// Progresso de 0 a 1. `nil` esconde a barra — só a prateleira "Lendo" a mostra.
    var progress: Double? = nil
    /// Onde esta capa publica o próprio frame, para poder ser promovida ao voo.
    var frameStore: CoverFrameStore? = nil
    /// `true` enquanto esta capa está a voar na camada da frente: aqui ela dá lugar.
    var isFlying: Bool = false

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
            .opacity(isFlying ? 0 : 1)
            .modifier(RecordsFrame(store: frameStore, id: book.id))

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

/// Só publica o frame quando há onde publicar.
private struct RecordsFrame: ViewModifier {
    let store: CoverFrameStore?
    let id: String

    func body(content: Content) -> some View {
        if let store {
            content.recordsCoverFrame(store, id: id)
        } else {
            content
        }
    }
}
