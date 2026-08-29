import SwiftUI
import SpriteKit

/// Tela de seleção de gêneros com efeito de "coisas caindo" (SpriteKit).
/// Os chips são views SwiftUI renderizadas em textura (ImageRenderer) → SKSpriteNode.
struct GenreOnboardingView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.displayScale) private var displayScale

    @State private var selected: [String] = []
    @State private var scene: GenrePhysicsScene?

    private let genres = GenreCatalog.all

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(Localization.Onboarding.genresTitleLine1.string)
                        .textStyle(.titleXL)
                        .foregroundStyle(.ink)
                    Text(Localization.Onboarding.genresTitleLine2.string)
                        .textStyle(.titleXL)
                        .foregroundStyle(.ink)

                    Text(Localization.Onboarding.genresSubtitle.string)
                        .textStyle(.bodySupporting)
                        .foregroundStyle(.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.gutterAuth)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.sm)
                .background(.surface)
                .zIndex(1)

                // Área da física
                GeometryReader { proxy in
                    ZStack {
                        Color.clear
                            .onAppear {
                                if scene == nil {
                                    scene = makeScene(size: proxy.size)
                                }
                            }
                        if let scene {
                            SpriteView(scene: scene, options: [.allowsTransparency])
                        }
                    }
                }

                VStack(spacing: Spacing.sm) {
                    Text(selected.isEmpty ? Localization.Onboarding.selectAtLeast.string : String(format: Localization.Onboarding.selected.string, selected.count))
                        .textStyle(.captionDefault)
                        .foregroundStyle(.inkMeta)

                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .textStyle(.captionDefault)
                            .foregroundStyle(.danger)
                    }

                    ReadUpButton(
                        title: Localization.Generic.continue.string,
                        variant: .primary,
                        isLoading: authManager.isLoading,
                        isEnabled: !selected.isEmpty
                    ) {
                        Task { await authManager.completeOnboarding(with: selected) }
                    }

                    ReadUpButton(
                        title: Localization.Onboarding.skipForNow.string,
                        variant: .tertiary
                    ) {
                        Task { await authManager.completeOnboarding(with: []) }
                    }
                }
                .padding(.horizontal, Spacing.gutterAuth)
                .padding(.bottom, Spacing.lg)
                .background(.surface)
                .zIndex(1)
            }
        }
    }

    // MARK: - Cena + render dos chips

    @MainActor
    private func makeScene(size: CGSize) -> GenrePhysicsScene {
        let renders = genres.map { genre in
            renderChip(genre)
        }
        return GenrePhysicsScene(
            size: size,
            chips: renders,
            gravityY: -9.0,
            bounce: 0.3,
            startDelay: 0.15
        ) { selectedIDs in
            selected = selectedIDs
        }
    }

    @MainActor
    private func renderChip(_ genre: Genre) -> GenrePhysicsScene.ChipRender {
        let normal = chipImage(genre: genre, selected: false)
        let selectedImg = chipImage(genre: genre, selected: true)
        let size = normal?.size ?? CGSize(width: 130, height: 48)
        return GenrePhysicsScene.ChipRender(
            id: genre.title,
            normal: SKTexture(image: normal ?? UIImage()),
            selected: SKTexture(image: selectedImg ?? UIImage()),
            size: size
        )
    }

    @MainActor
    private func chipImage(genre: Genre, selected: Bool) -> UIImage? {
        let renderer = ImageRenderer(content: chipView(genre: genre, selected: selected))
        renderer.scale = displayScale
        return renderer.uiImage
    }

    // ponytail: os chips são bitmaps dentro de um SpriteView, então não têm rótulo de
    // VoiceOver nem respeitam Dynamic Type. Caminho de upgrade: uma grade de chips
    // SwiftUI reais com `Layout`, que é o que o frame do Figma mostra de fato.
    private func chipView(genre: Genre, selected: Bool) -> some View {
        GenreChip(title: genre.localizedTitle, isSelected: selected)
            // Fixa light mode: não há dark mode neste design system, mas o ImageRenderer
            // usa o esquema de cores do dispositivo e geraria texturas erradas em modo escuro.
            .environment(\.colorScheme, .light)
    }
}

#Preview {
    GenreOnboardingView()
        .environment(AuthManager())
}
