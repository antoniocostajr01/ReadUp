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

    private let palette: [Color] = [
        .emphasis, .indigo, .orange, .pink, .teal,
        .purple, .blue, .brown, .red, .mint, .cyan
    ]
    
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(Localization.Onboarding.genresTitle.string)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(Localization.Onboarding.genresSubtitle.string)
                        .font(.subheadline)
                        .foregroundStyle(.secundaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)
                .background(.backgroundPrimary)
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
                
                VStack(spacing: 10) {
                    Text(selected.isEmpty ? Localization.Onboarding.selectAtLeast.string : String(format: Localization.Onboarding.selected.string, selected.count))
                        .font(.footnote)
                        .foregroundStyle(.secundaryLabel)

                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
            
                    AuthPrimaryButton(
                        title: Localization.Generic.continue.string,
                        isLoading: authManager.isLoading,
                        isEnabled: !selected.isEmpty
                    ) {
                        Task { await authManager.completeOnboarding(with: selected) }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(.backgroundPrimary)
                .zIndex(1)
            }
        }
    }

    // MARK: - Cena + render dos chips

    @MainActor
    private func makeScene(size: CGSize) -> GenrePhysicsScene {
        let renders = genres.enumerated().map { index, genre in
            renderChip(genre, color: palette[index % palette.count])
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
    private func renderChip(_ genre: Genre, color: Color) -> GenrePhysicsScene.ChipRender {
        let normal = chipImage(genre: genre, color: color, selected: false)
        let selectedImg = chipImage(genre: genre, color: color, selected: true)
        let size = normal?.size ?? CGSize(width: 130, height: 48)
        return GenrePhysicsScene.ChipRender(
            id: genre.title,
            normal: SKTexture(image: normal ?? UIImage()),
            selected: SKTexture(image: selectedImg ?? UIImage()),
            size: size
        )
    }

    @MainActor
    private func chipImage(genre: Genre, color: Color, selected: Bool) -> UIImage? {
        let renderer = ImageRenderer(content: chipView(genre: genre, color: color, selected: selected))
        renderer.scale = displayScale
        return renderer.uiImage
    }

    private func chipView(genre: Genre, color: Color, selected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: genre.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(selected ? .white : color)
            Text(genre.localizedTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(selected ? .white : Color(uiColor: .label))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule().fill(selected ? Color.emphasis : Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            Capsule().strokeBorder(selected ? Color.emphasis : color.opacity(0.55),
                                   lineWidth: selected ? 2.5 : 1.2)
        )
    }
}

#Preview {
    GenreOnboardingView()
        .environment(AuthManager())
}
