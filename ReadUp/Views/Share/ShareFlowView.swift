import SwiftUI

/// O carrossel que abre o compartilhamento. Figma `10b · Share — options`.
///
/// Duas maneiras de publicar a mesma sessão: com uma foto sua atrás do card, ou o
/// card sozinho. Substitui o botão "Share to Instagram" que copiava a imagem para a
/// área de transferência e mandava o usuário colar.
struct ShareFlowView: View {
    let story: SessionStory
    /// Chamado quando o usuário publica de fato no Instagram — quem abre o fluxo
    /// decide o que fazer depois (hoje, `SessionSummary` volta pra Home).
    var onPublished: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var option: Option = .photo
    @State private var path = NavigationPath()
    /// Vive aqui, e não em cada tela, porque é a mesma posição do começo ao fim:
    /// o que o usuário enquadra na câmera é o que o editor recebe.
    @State private var cardTransform = StickerTransform()

    /// O card no carrossel é uma miniatura da tela inteira, não do card.
    private static let previewSize = CGSize(width: 265, height: 471)

    enum Option: Int, CaseIterable, Hashable {
        case photo, card

        var title: String {
            switch self {
            case .photo: Localization.SessionSummary.optionPhotoTitle.string
            case .card: Localization.SessionSummary.optionCardTitle.string
            }
        }

        var caption: String {
            switch self {
            case .photo: Localization.SessionSummary.optionPhotoCaption.string
            case .card: Localization.SessionSummary.optionCardCaption.string
            }
        }
    }

    private enum Route: Hashable {
        case camera
        case editor(UIImage)
        case ready
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header

                TabView(selection: $option) {
                    ForEach(Option.allCases, id: \.self) { option in
                        card(for: option)
                            .tag(option)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: Self.previewSize.height + Spacing.xl)

                caption

                dots
                    .padding(.top, Spacing.lg)

                Spacer(minLength: Spacing.lg)

                ReadUpButton(title: Localization.SessionSummary.continueAction.string) {
                    path.append(option == .photo ? Route.camera : Route.ready)
                }
                .padding(.horizontal, Spacing.gutterList)
                .padding(.bottom, Spacing.xl)
            }
            .background(Palette.surface)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .camera:
                    StoryCameraView(story: story, card: $cardTransform) { photo in
                        path.append(Route.editor(photo))
                    }
                case .editor(let photo):
                    StoryEditorView(story: story, photo: photo, card: $cardTransform, onPublished: publish)
                case .ready:
                    StoryReadyView(story: story, onPublished: publish)
                }
            }
        }
    }

    /// Publicou no Instagram: avisa quem abriu o fluxo e fecha tudo, de qualquer degrau.
    private func publish() {
        onPublished()
        dismiss()
    }

    // MARK: - Chrome

    private var header: some View {
        ZStack {
            Text(Localization.SessionSummary.share.string)
                .textStyle(.titleSecondary)
                .foregroundStyle(Palette.ink)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.surfaceControl))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(Localization.Generic.close.string))

                Spacer()
            }
        }
        .padding(.horizontal, Spacing.gutterList)
        .padding(.top, Spacing.md)
    }

    private var caption: some View {
        VStack(spacing: Spacing.xs + 2) {
            Text(option.title)
                .textStyle(.field)
                .foregroundStyle(Palette.ink)

            Text(option.caption)
                .textStyle(.captionDefault)
                .foregroundStyle(Palette.inkMuted)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .animation(Motion.fast, value: option)
    }

    private var dots: some View {
        HStack(spacing: Spacing.sm - 2) {
            ForEach(Option.allCases, id: \.self) { item in
                Capsule()
                    .fill(item == option ? Palette.ink : Palette.inkDisclosure)
                    .frame(width: item == option ? 16 : 6, height: 6)
            }
        }
        .animation(Motion.fast, value: option)
        .accessibilityHidden(true)
    }

    // MARK: - As duas opções

    @ViewBuilder
    private func card(for option: Option) -> some View {
        Group {
            switch option {
            case .photo: photoOption
            case .card: cardOption
            }
        }
        .frame(width: Self.previewSize.width, height: Self.previewSize.height)
        .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                .strokeBorder(Palette.border, lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }

    /// A miniatura da câmera: o card pousado sobre a foto, com a foto em volta.
    private var photoOption: some View {
        ZStack(alignment: .topLeading) {
            Palette.surfaceNight

            miniature(skin: .sticker, widthFraction: 268.0 / 393.0)
                .frame(
                    width: Self.previewSize.width,
                    height: Self.previewSize.height,
                    alignment: .center
                )

            Image(systemName: "camera.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.inkOnArt)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Palette.ink.opacity(0.72)))
                .overlay(Circle().strokeBorder(Palette.inkOnArt.opacity(0.28), lineWidth: 1))
                .padding(Spacing.md + 2)
        }
    }

    private var cardOption: some View {
        ZStack {
            Palette.surface
            miniature(skin: .solid, widthFraction: 1)
        }
    }

    /// O card real, encolhido. Não uma recriação — a miniatura tem de envelhecer
    /// junto com o card que vai ser publicado.
    private func miniature(
        skin: SessionSummaryShareCard.Skin,
        widthFraction: CGFloat
    ) -> some View {
        let target = Self.previewSize.width * widthFraction
        return SessionSummaryShareCard(story: story, skin: skin)
            .scaleEffect(target / SessionSummaryShareCard.size.width)
            .frame(
                width: target,
                height: target * (SessionSummaryShareCard.size.height / SessionSummaryShareCard.size.width)
            )
    }
}

#Preview {
    ShareFlowView(story: .preview)
}
