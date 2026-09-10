import SwiftUI

/// Uma capa na grade da Library.
///
/// Substitui a antiga `ShelfCover` das prateleiras horizontais. A sombra é intencional:
/// capa de livro é objeto empilhado, uma das duas coisas no sistema que ainda projetam
/// sombra. O badge de status só aparece quando não há filtro ativo — com filtro, todas
/// as capas têm o mesmo status e o badge não diria nada.
struct GridCover: View {
    let book: Book
    /// A largura da coluna. A altura sai da proporção de capa (0.68), a mesma da PoC.
    let width: CGFloat
    /// Esconde o badge quando a grade já está filtrada por um status.
    var showsStatus: Bool = true
    /// Onde esta capa publica o próprio frame, para poder ser promovida ao voo.
    var frameStore: CoverFrameStore? = nil
    /// `false` congela o registo do frame. Durante a explosão a capa está deslocada e
    /// escalada, e gravar aí faria o voo de volta partir do sítio errado.
    var isRecording: Bool = true
    /// `true` enquanto esta capa está a voar na camada da frente: aqui ela dá lugar.
    var isFlying: Bool = false

    private var height: CGFloat { width / 0.68 }

    var body: some View {
        BookCoverView(
            coverUrl: book.coverUrl,
            width: width,
            height: height,
            cornerRadius: Radius.cover,
            title: book.title,
            author: book.author
        )
        .overlay(alignment: .topLeading) {
            if showsStatus {
                Image(systemName: book.status.icon)
                    .font(.iconLabel)
                    .foregroundStyle(Palette.onBrand)
                    .frame(width: 26, height: 26)
                    .background(book.status.tint, in: .circle)
                    .padding(Spacing.sm)
            }
        }
        .coverShadow(.coverTilt)
        .opacity(isFlying ? 0 : 1)
        .modifier(RecordsFrame(store: isRecording ? frameStore : nil, id: book.id))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(book.title), \(book.author), \(book.status.displayName)"))
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
