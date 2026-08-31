import SwiftUI

extension View {

    /// Liga esta capa ao voo entre a prateleira/linha e o herói do detalhe.
    ///
    /// Fica na **capa em si**, nunca no botão que a envolve: com o botão inteiro
    /// marcado, o que voa é a caixa com barra de progresso e legenda junto, e a
    /// proporção muda no meio do caminho. Sem namespace não faz nada — a mesma view
    /// serve telas que não vieram de uma capa.
    @ViewBuilder
    func hero(_ namespace: Namespace.ID?, id: String) -> some View {
        if let namespace {
            matchedGeometryEffect(id: id, in: namespace)
        } else {
            self
        }
    }
}

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
        AsyncImage(url: coverUrl.flatMap(URL.init(string:))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                placeholder
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var placeholder: some View {
        // As proporções vêm da capa herói do Figma (`47:1822`, 224×320): título 44pt,
        // autor 17pt, respiro 22×26. Guardadas como razão porque o mesmo placeholder
        // serve capa herói, linha de busca e miniatura — um TypeRole fixo não cobre as três.
        let titleSize = width * (44.0 / 224.0)
        let authorSize = width * (17.0 / 224.0)
        let inset = width * (22.0 / 224.0)

        ZStack {
            Palette.surfaceFill

            if let title {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.custom(Face.serif, size: titleSize))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)

                    Spacer(minLength: Spacing.xs)

                    if let author {
                        Text(author)
                            .font(.custom(Face.serifItalic, size: authorSize))
                            .foregroundStyle(Palette.inkSoft)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, inset)
                .padding(.vertical, inset * (26.0 / 22.0))
            }
        }
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
