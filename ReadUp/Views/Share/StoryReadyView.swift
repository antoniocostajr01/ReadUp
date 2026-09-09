import SwiftUI

/// O card sozinho, pronto para publicar. Figma `10e · Card ready`.
///
/// O outro braço do carrossel: sem foto, sem edição — só o story renderizado e os
/// mesmos dois destinos do editor.
struct StoryReadyView: View {
    let story: SessionStory

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: Spacing.lg)

            GeometryReader { geo in
                let width = min(geo.size.width - Spacing.gutterList * 2, geo.size.height * 9 / 16)
                card(width: width)
                    .frame(width: geo.size.width, height: geo.size.height)
            }

            Spacer(minLength: Spacing.lg)

            StoryDestinations(image: render)
                .padding(.horizontal, Spacing.gutterList)
                .padding(.bottom, Spacing.xl)
        }
        .background(Palette.surface)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func card(width: CGFloat) -> some View {
        SessionSummaryShareCard(story: story, skin: .solid)
            .scaleEffect(width / SessionSummaryShareCard.size.width)
            .frame(
                width: width,
                height: width * (SessionSummaryShareCard.size.height / SessionSummaryShareCard.size.width)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                    .strokeBorder(Palette.border, lineWidth: 1)
            )
    }

    private var header: some View {
        ZStack {
            Text(Localization.SessionSummary.share.string)
                .textStyle(.titleSecondary)
                .foregroundStyle(Palette.ink)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.surfaceControl))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(Localization.Generic.back.string))

                Spacer()
            }
        }
        .padding(.horizontal, Spacing.gutterList)
        .padding(.top, Spacing.md)
    }

    /// A imagem publicada é o card na pele `.solid`, a 1080×1920.
    @MainActor
    private func render() -> UIImage? {
        SessionSummaryShareCard(story: story, skin: .solid).render()
    }
}

#Preview {
    NavigationStack {
        StoryReadyView(story: .preview)
    }
}
