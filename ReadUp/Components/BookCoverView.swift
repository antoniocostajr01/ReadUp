import SwiftUI

/// Capa de livro carregada por URL (backend devolve `coverUrl`).
///
/// Sem capa, desenha o **placeholder tipográfico** do design: título serifado no
/// topo, autor em itálico no rodapé, sobre `surface/fill`. Figma `47:1822`.
/// Passe `title`/`author` para obtê-lo; sem eles a capa vazia é só o preenchimento.
struct BookCoverView: View {
    let coverUrl: String?
    let width: CGFloat
    let height: CGFloat
    var cornerRadius: CGFloat = 10
    var title: String? = nil
    var author: String? = nil

    var body: some View {
        CoverImage(url: coverUrl.flatMap(URL.init(string:))) { placeholder }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var placeholder: some View {
        CoverPlaceholder(title: title, author: author, width: width)
    }
}

#Preview {
    HStack(spacing: 20) {
        BookCoverView(coverUrl: nil, width: 224, height: 320, cornerRadius: Radius.coverLg,
                      title: "1984", author: "George Orwell")
        BookCoverView(coverUrl: nil, width: 48, height: 68, cornerRadius: Radius.coverSm,
                      title: "Sapiens", author: "Y. N. Harari")
    }
    .padding()
    .background(Palette.surface)
}
