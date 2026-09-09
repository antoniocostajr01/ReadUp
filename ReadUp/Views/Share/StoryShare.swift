import SwiftUI
import UIKit

/// Os dados que o card de story precisa. Existe para os quatro pontos do fluxo
/// (carrossel, câmera, editor, card pronto) passarem uma coisa só em vez de seis.
struct SessionStory: Equatable {
    let book: Book
    let coverImage: UIImage?
    let pagesRead: Int
    let sessionTime: String
    let totalProgress: Int
    let completionPercentage: Int
    /// Quem leu. Assina o card.
    let userName: String
    /// Já como `UIImage`: o `ImageRenderer` é síncrono e não espera um download.
    let userAvatar: UIImage?
}

extension SessionStory {
    static let preview = SessionStory(
        book: Book(
            id: "preview",
            title: "1984",
            author: "George Orwell",
            numberOfPages: 328,
            details: "",
            coverUrl: nil,
            status: .reading
        ),
        coverImage: nil,
        pagesRead: 10,
        sessionTime: "24:07",
        totalProgress: 158,
        completionPercentage: 45,
        userName: "Antonio Costa",
        userAvatar: nil
    )
}

// MARK: - Estado dos gestos

/// Posição, escala e rotação de um elemento arrastável.
///
/// Cada eixo guarda um valor **firmado** e um **ao vivo**: os gestos do SwiftUI
/// reportam sempre a partir do início do gesto, então somar direto no firmado faria a
/// peça saltar a cada novo toque.
struct StickerTransform {
    var offset: CGSize = .zero
    var scale: CGFloat = 1
    var rotation: Angle = .zero

    var liveOffset: CGSize = .zero
    var liveScale: CGFloat = 1
    var liveRotation: Angle = .zero

    var totalOffset: CGSize {
        CGSize(width: offset.width + liveOffset.width, height: offset.height + liveOffset.height)
    }
    /// Limitada: sem teto um pinch some com a peça (escala ~0) ou a estoura para
    /// fora da tela, e nos dois casos ela fica impossível de recuperar.
    var totalScale: CGFloat { min(max(scale * liveScale, 0.3), 4) }
    var totalRotation: Angle { rotation + liveRotation }

    mutating func commitOffset() { offset = totalOffset; liveOffset = .zero }
    mutating func commitScale() { scale = totalScale; liveScale = 1 }
    mutating func commitRotation() { rotation = totalRotation; liveRotation = .zero }
}


/// Arrastar, pinçar e girar. O card e cada texto usam o mesmo gesto — o que o
/// usuário aprende num vale no outro, e há uma implementação só para manter.
func stickerGesture(_ transform: Binding<StickerTransform>) -> some Gesture {
    let drag = DragGesture()
        .onChanged { transform.wrappedValue.liveOffset = $0.translation }
        .onEnded { _ in transform.wrappedValue.commitOffset() }

    let magnify = MagnifyGesture()
        .onChanged { transform.wrappedValue.liveScale = $0.magnification }
        .onEnded { _ in transform.wrappedValue.commitScale() }

    let rotate = RotateGesture()
        .onChanged { transform.wrappedValue.liveRotation = $0.rotation }
        .onEnded { _ in transform.wrappedValue.commitRotation() }

    return drag.simultaneously(with: magnify.simultaneously(with: rotate))
}

/// Para onde uma imagem de story pode ir.
///
/// Nenhum dos dois caminhos passa pela galeria nem pede que o usuário cole nada —
/// era exatamente esse trabalho manual que o fluxo antigo empurrava para ele.
enum StoryDestination {

    /// Abre o Instagram com a imagem **já posta** como fundo do story.
    ///
    /// O mecanismo é o `UIPasteboard`, mas não é o truque antigo de "copie e cole":
    /// os itens vão num tipo privado (`com.instagram.sharedSticker.*`) que só o
    /// Instagram lê, e ele os consome sozinho ao abrir. O usuário não cola nada.
    ///
    /// Retorna `false` quando o Instagram não está instalado — aí o chamador cai no
    /// share nativo.
    ///
    /// ponytail: sem `sourceApplication`. A Meta documenta um App ID do Facebook na
    /// query, mas o hand-off funciona sem ele nas versões atuais do app; se algum dia
    /// parar de funcionar, é o primeiro lugar a olhar — e o fallback já cobre a queda.
    @MainActor
    static func instagramStories(_ image: UIImage) -> Bool {
        let facebookAppID = Bundle.main.object(forInfoDictionaryKey: "FACEBOOK_APP_ID") as? String ?? ""

        // Sem App ID válido o Instagram rejeita o compartilhamento.
        guard !facebookAppID.isEmpty,
              facebookAppID != "YOUR_FACEBOOK_APP_ID_HERE",
              let url = URL(string: "instagram-stories://share?source_application=\(facebookAppID)"),
              UIApplication.shared.canOpenURL(url),
              let png = image.pngData()
        else { return false }

        UIPasteboard.general.setItems(
            [[
                "com.instagram.sharedSticker.backgroundImage": png,
                "com.instagram.sharedSticker.appID": facebookAppID
            ]],
            options: [.expirationDate: Date().addingTimeInterval(5 * 60)]
        )
        UIApplication.shared.open(url)
        return true
    }

    /// Grava o PNG num arquivo temporário para o share sheet.
    ///
    /// Um `URL` e não a `UIImage`: com a imagem crua, várias extensões recebem um
    /// JPEG recomprimido e perdem a transparência.
    static func temporaryFile(for image: UIImage) -> URL? {
        guard let png = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReadUp_Session.png")
        do {
            try png.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

/// Fecha o fluxo de compartilhamento inteiro, de qualquer degrau dele.
///
/// Pelo ambiente e não por um closure passado de mão em mão: quem precisa disso é o
/// `StoryDestinations`, dois níveis abaixo, e o caminho até lá atravessaria o editor
/// e a tela do card pronto sem que nenhum dos dois tivesse o que fazer com ele.
extension EnvironmentValues {
    @Entry var dismissStoryFlow: () -> Void = {}
}

/// O share sheet do sistema.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Destinos

/// Os dois caminhos de saída, usados no fim do editor e na tela do card pronto.
///
/// `onDark` inverte a pílula primária: sobre foto ela é creme com tipo ink, sobre
/// creme é ink com tipo creme. Mesmo componente para os dois porque a única coisa que
/// muda entre as telas é o chão atrás.
struct StoryDestinations: View {
    let image: () -> UIImage?
    var onDark: Bool = false

    @Environment(\.dismissStoryFlow) private var dismissStoryFlow

    @State private var shareURL: URL?
    @State private var isShowingShareSheet = false

    var body: some View {
        HStack(spacing: Spacing.md + 2) {
            Button {
                guard let image = image() else { return }
                // Entregue ao Instagram, o trabalho aqui acabou: o fluxo se fecha
                // atrás do usuário, que volta do story direto para o resumo da
                // sessão em vez de para o editor que já não tem o que fazer.
                if StoryDestination.instagramStories(image) {
                    dismissStoryFlow()
                } else {
                    presentShareSheet(for: image)
                }
            } label: {
                HStack(spacing: Spacing.sm + 1) {
                    InstagramGlyph(size: 20)

                    Text(Localization.SessionSummary.shareToStories.string)
                        .textStyle(.field)
                }
                .foregroundStyle(onDark ? Palette.ink : Palette.onBrand)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(onDark ? Palette.inkInverse : Palette.brand))
            }
            .buttonStyle(.plain)

            Button {
                if let image = image() { presentShareSheet(for: image) }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(onDark ? Palette.inkOnArt : Palette.ink)
                    .frame(width: 54, height: 54)
                    .background(
                        Circle().fill(onDark ? Palette.ink.opacity(0.18) : .clear)
                    )
                    .overlay(
                        Circle().strokeBorder(
                            onDark ? Palette.inkOnArt.opacity(0.4) : Palette.borderStrong,
                            lineWidth: 1
                        )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Localization.SessionSummary.shareOther.string))
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func presentShareSheet(for image: UIImage) {
        shareURL = StoryDestination.temporaryFile(for: image)
        isShowingShareSheet = shareURL != nil
    }
}

/// A câmera do Instagram, em traço.
///
/// Desenhada e não importada de propósito: a marca oficial em gradiente tem regras de
/// uso próprias, enquanto o glifo monocromático é o que a Meta indica para um botão
/// de "compartilhar no Instagram". Assim ele também herda a cor do rótulo e continua
/// certo nas duas pílulas — a creme sobre foto e a ink sobre creme.
struct InstagramGlyph: View {
    var size: CGFloat = 20

    var body: some View {
        // Proporções de um viewBox 24, escaladas para o tamanho pedido.
        let unit = size / 24

        ZStack {
            RoundedRectangle(cornerRadius: 6.6 * unit, style: .continuous)
                .strokeBorder(lineWidth: 1.9 * unit)
                .frame(width: 18 * unit, height: 18 * unit)

            Circle()
                .strokeBorder(lineWidth: 1.9 * unit)
                .frame(width: 9.2 * unit, height: 9.2 * unit)

            Circle()
                .frame(width: 2.3 * unit, height: 2.3 * unit)
                .offset(x: 5.1 * unit, y: -5.1 * unit)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Chrome sobre foto

/// Um botão redondo que continua legível seja qual for a foto atrás.
///
/// Chão de ink a 72% com fio creme: 6.5:1 para o glifo mesmo contra uma foto branca.
/// A primeira tentativa foi creme translúcido e sumia em qualquer cena clara.
struct PhotoChromeButton: View {
    let systemImage: String
    var size: CGFloat = 44
    var glyphSize: CGFloat = 18
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: glyphSize, weight: .medium))
                .foregroundStyle(Palette.inkOnArt)
                .frame(width: size, height: size)
                .background(Circle().fill(Palette.ink.opacity(0.72)))
                .overlay(Circle().strokeBorder(Palette.inkOnArt.opacity(0.28), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 10, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(systemImage))
    }
}

// MARK: - Previews

#Preview("Destinations — Light") {
    VStack {
        Spacer()
        StoryDestinations(image: {
            UIImage(systemName: "photo")!
        })
        .padding(.horizontal, Spacing.gutterList)
    }
    .padding(.bottom, Spacing.xl)
    .background(Palette.surface)
}

#Preview("Destinations — Dark") {
    VStack {
        Spacer()
        StoryDestinations(image: {
            UIImage(systemName: "photo")!
        }, onDark: true)
        .padding(.horizontal, Spacing.gutterList)
    }
    .padding(.bottom, Spacing.xl)
    .background(Palette.surfaceNight)
}

#Preview("PhotoChromeButton") {
    ZStack {
        Palette.surfaceNight.ignoresSafeArea()

        HStack(spacing: Spacing.lg) {
            PhotoChromeButton(systemImage: "xmark", size: 38, glyphSize: 14) {}
            PhotoChromeButton(systemImage: "arrow.trianglehead.2.clockwise.rotate.90", size: 48, glyphSize: 20) {}
        }
    }
}
