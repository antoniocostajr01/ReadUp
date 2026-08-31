import SwiftUI

/// O espaço de coordenadas em que as capas publicam os seus frames.
enum HeroSpace {
    static let name = "hero"
}

/// Onde a capa promovida está agora, e com que opacidade.
struct HeroPlacement: Equatable {
    var frame: CGRect = .zero
    var opacity: Double = 1

    var isPlaced: Bool { frame != .zero }
}

/// Os frames das capas visíveis.
///
/// Classe simples de propósito: escrever aqui a cada frame de scroll não invalida view
/// nenhuma. Num `@State` isto redesenharia a lista inteira enquanto o dedo se mexe.
@MainActor
final class CoverFrameStore {
    private var frames: [String: CGRect] = [:]

    func record(_ frame: CGRect, for id: String) { frames[id] = frame }
    func frame(for id: String) -> CGRect? { frames[id] }
}

extension View {

    /// Publica o frame desta capa, para quando ela for promovida à camada da frente.
    func recordsCoverFrame(_ store: CoverFrameStore, id: String) -> some View {
        onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(HeroSpace.name))
        } action: { frame in
            store.record(frame, for: id)
        }
    }
}

/// A capa promovida à camada da frente de um `ZStack`.
///
/// Esta view **não sai de tela** durante a troca: quem muda é a camada de baixo. É a
/// diferença para o `matchedGeometryEffect`, onde existem duas capas com o frame
/// interpolado e o conteúdo em cross-fade — lá, uma imagem que carregou numa e não na
/// outra aparece como um salto no meio do voo. Aqui é uma capa só, do começo ao fim.
///
/// Não anima nada por conta própria: quem a apresenta é que decide quando a mudança de
/// `placement` vale uma mola (a troca de tela) e quando não vale (o dedo a rolar).
struct FlyingCover: View {
    let coverUrl: String?
    let title: String
    let author: String
    let placement: HeroPlacement

    var body: some View {
        BookCoverView(
            coverUrl: coverUrl,
            width: placement.frame.width,
            height: placement.frame.height,
            cornerRadius: Radius.coverLg,
            title: title,
            author: author
        )
        .coverShadow(.coverHero)
        .position(x: placement.frame.midX, y: placement.frame.midY)
        .opacity(placement.opacity)
        .allowsHitTesting(false)
    }
}
