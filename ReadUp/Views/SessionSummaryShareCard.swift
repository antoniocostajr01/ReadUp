import SwiftUI

struct SessionSummaryShareCard: View {

    enum Skin {
        /// O story sozinho, de borda a borda, sobre creme.
        case solid
        /// Sobre a foto do usuário — sem fundo.
        case sticker

        var hasGround: Bool { self == .solid }

        /// Títulos, números, nome do leitor.
        var primaryInk: Color { self == .solid ? Palette.ink : Palette.inkOnArt }
        /// Autor e rodapé.
        var secondaryInk: Color { self == .solid ? Palette.inkMuted : Palette.inkOnArt.opacity(0.88) }
        /// Os rótulos versaletes de 11pt.
        var labelInk: Color { self == .solid ? Palette.inkStrongMuted : Palette.inkOnArt.opacity(0.92) }
        /// Os fios entre as colunas de estatística.
        var ruleColor: Color { self == .solid ? Palette.rule : Palette.inkOnArt.opacity(0.4) }
    }

    let story: SessionStory
    var skin: Skin = .solid

    /// 9:16. O export sai a 3× disto — 1080×1920, o tamanho de um story.
    static let size = CGSize(width: 360, height: 640)
    static let exportScale: CGFloat = 3

    private let coverSize = CGSize(width: 196, height: 268)

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: Spacing.md)

            cover

            Spacer(minLength: Spacing.md)

            stats

            Spacer(minLength: Spacing.lg)

            signature

            footer
                .padding(.top, Spacing.sm + 2)
        }
        .padding(.top, Spacing.md + Spacing.lg)
        .padding(.bottom, Spacing.xl)
        .padding(.horizontal, Spacing.md + Spacing.lg)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(skin.hasGround ? Palette.surfaceRaised : .clear)
        .shadow(color: skin.hasGround ? .clear : .black.opacity(0.5), radius: 5, y: 1)
    }

    // MARK: - Blocos

    private var header: some View {
        VStack(spacing: Spacing.xs + 2) {
            Text(Localization.SessionSummary.storyOverline.string)
                .textStyle(.overline)
                .textCase(.uppercase)
                .foregroundStyle(skin.labelInk)

            Text(story.book.title)
                .textStyle(.titlePrimary)
                .foregroundStyle(skin.primaryInk)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(story.book.author)
                .textStyle(.authorRow)
                .foregroundStyle(skin.secondaryInk)
                .lineLimit(1)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var cover: some View {
        Group {
            if let coverImage = story.coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
            } else {
                CoverPlaceholder(
                    title: story.book.title,
                    author: story.book.author,
                    width: coverSize.width
                )
            }
        }
        .frame(width: coverSize.width, height: coverSize.height)
        .clipShape(RoundedRectangle(cornerRadius: Radius.coverLg, style: .continuous))
        .coverShadow(.coverHero)
    }

    private var stats: some View {
        HStack(spacing: 0) {
            statCell(Localization.SessionSummary.pagesRead.string, "\(story.pagesRead)")
            rule
            statCell(Localization.SessionSummary.sessionTime.string, story.sessionTime)
            rule
            statCell(Localization.SessionSummary.totalCompletion.string, "\(story.completionPercentage)%")
        }
        .frame(maxWidth: .infinity)
    }

    private func statCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: Spacing.sm - 1) {
            Text(label)
                .textStyle(.overline)
                .textCase(.uppercase)
                .foregroundStyle(skin.labelInk)

            Text(value)
                .textStyle(.displayMetric)
                .foregroundStyle(skin.primaryInk)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var rule: some View {
        Rectangle()
            .fill(skin.ruleColor)
            .frame(width: 1, height: 30)
    }

    /// Quem leu. A assinatura do leitor, com a foto do perfil.
    private var signature: some View {
        HStack(spacing: Spacing.sm + 1) {
            avatar

            Text(story.userName)
                .textStyle(.field)
                .foregroundStyle(skin.primaryInk)
                .lineLimit(1)
        }
    }

    private var avatar: some View {
        Group {
            if let userAvatar = story.userAvatar {
                Image(uiImage: userAvatar)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(skin.hasGround ? Palette.surfaceFill : Palette.inkOnArt.opacity(0.2))
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(skin.secondaryInk)
                }
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(skin.ruleColor, lineWidth: 1))
    }

    private var footer: some View {
        HStack(spacing: Spacing.sm - 2) {
            // A marca solta, não o tile do ícone: ao lado de texto, o quadrado creme
            // do `AppIcon` leria como um segundo card.
            Image(.readUpIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)

            Text(Localization.SessionSummary.madeWith.string)
                .textStyle(.captionFine)
                .foregroundStyle(skin.secondaryInk)
        }
    }
}

// MARK: - Render

extension SessionSummaryShareCard {

    /// Rasteriza o card a 1080×1920.
    ///
    /// Síncrono de propósito: o `ImageRenderer` não espera um `AsyncImage`, então a
    /// capa e o avatar têm de chegar aqui já como `UIImage`.
    @MainActor
    func render() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = Self.exportScale
        renderer.isOpaque = skin.hasGround
        return renderer.uiImage
    }
}

#Preview("Solid") {
    SessionSummaryShareCard(story: .preview)
}

#Preview("Sticker over a photo") {
    ZStack {
        LinearGradient(
            colors: [Palette.inkStrongMuted, Palette.surfaceNight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        SessionSummaryShareCard(story: .preview, skin: .sticker)
    }
    .ignoresSafeArea()
}
