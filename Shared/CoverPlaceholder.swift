//
//  CoverPlaceholder.swift
//  ReadUp
//

import SwiftUI

/// Placeholder tipográfico de capa: título serifado no topo, autor em itálico no
/// rodapé, sobre `surface/fill`. Figma `47:1822`.
///
/// As proporções vêm da capa herói do Figma (`47:1822`, 224×320): título 44pt,
/// autor 17pt, respiro 22×26. Guardadas como razão da largura porque o mesmo
/// placeholder serve capa herói, linha de busca e miniatura — um TypeRole fixo
/// não cobre as três.
///
/// Vive em `Shared/` porque a Live Activity também o desenha: a extensão não
/// consegue baixar `coverUrl`, então este placeholder é a capa que ela mostra.
struct CoverPlaceholder: View {
    let title: String?
    let author: String?
    /// Largura da capa — as proporções acima são razões dela.
    let width: CGFloat

    var body: some View {
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
