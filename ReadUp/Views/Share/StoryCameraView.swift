@preconcurrency import AVFoundation
import SwiftUI

/// A câmera do fluxo de compartilhamento. Figma `10c · Camera`.
///
/// Enquadra a foto com o card já por cima, e o card já se move aqui: arrastar,
/// pinçar e girar antes do disparo é o mesmo gesto do editor, e a posição escolhida
/// atravessa a captura em vez de ser refeita do zero depois.
struct StoryCameraView: View {
    let story: SessionStory
    @Binding var card: StickerTransform
    let onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var camera = StoryCamera()

    /// 296 de 393 — a largura que ainda deixa o rodapé do card acima do seletor de
    /// câmera. A 313 a assinatura do leitor ficava por baixo dele.
    static func cardWidth(in size: CGSize) -> CGFloat { size.width * 296 / 393 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Palette.surfaceNight

                CameraPreview(session: camera.session)
                    .ignoresSafeArea()

                if camera.access == .denied {
                    deniedNotice
                } else {
                    // Centralizado e sem recuo: é exatamente o repouso do card no
                    // editor, então o que o usuário enquadra aqui é o que ele
                    // encontra lá — antes, a mesma posição saltava 100pt na captura.
                    SessionSummaryShareCard(story: story, skin: .sticker)
                        .scaleEffect(Self.cardWidth(in: geo.size) / SessionSummaryShareCard.size.width)
                        .frame(
                            width: Self.cardWidth(in: geo.size),
                            height: Self.cardWidth(in: geo.size) * (SessionSummaryShareCard.size.height / SessionSummaryShareCard.size.width)
                        )
                        .scaleEffect(card.totalScale)
                        .rotationEffect(card.totalRotation)
                        .offset(card.totalOffset)
                        .gesture(stickerGesture($card))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                controls
            }
        }
        .background(Palette.surfaceNight)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(false)
        .task { await camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: camera.captured) { _, photo in
            if let photo { onCapture(photo) }
        }
    }

    // MARK: - Chrome

    private var controls: some View {
        VStack {
            HStack {
                PhotoChromeButton(systemImage: "xmark", size: 38, glyphSize: 14) { dismiss() }
                Spacer()
            }
            .padding(.horizontal, Spacing.gutterList)
            .padding(.top, Spacing.md)

            Spacer()

            if camera.access == .granted {
                HStack {
                    Spacer()
                    shutter
                    Spacer()
                }
                .overlay(alignment: .trailing) {
                    PhotoChromeButton(systemImage: "arrow.trianglehead.2.clockwise.rotate.90", size: 48, glyphSize: 20) {
                        camera.flip()
                    }
                    .padding(.trailing, Spacing.gutterList)
                }
                .padding(.bottom, Spacing.xl + Spacing.md)
            }
        }
    }

    private var shutter: some View {
        Button { camera.capture() } label: {
            Circle()
                .fill(Palette.ink.opacity(0.35))
                .frame(width: 74, height: 74)
                .overlay(Circle().strokeBorder(Palette.inkOnArt, lineWidth: 3))
                .overlay(Circle().fill(Palette.inkOnArt).frame(width: 58, height: 58))
                .shadow(color: .black.opacity(0.35), radius: 10, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(Localization.SessionSummary.optionPhotoTitle.string))
    }

    private var deniedNotice: some View {
        VStack(spacing: Spacing.lg) {
            Text(Localization.SessionSummary.cameraDenied.string)
                .textStyle(.bodyDefault)
                .foregroundStyle(Palette.inkOnArt)
                .multilineTextAlignment(.center)

            Button(Localization.SessionSummary.cameraOpenSettings.string) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .textStyle(.field)
            .foregroundStyle(Palette.inkOnArt)
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Sessão

/// A sessão de captura. Um objeto e não `@State` solto porque a configuração da
/// `AVCaptureSession` tem de sair da main thread e sobreviver a redesenhos da View.
@Observable
@MainActor
final class StoryCamera {

    enum Access { case unknown, granted, denied }

    let session = AVCaptureSession()
    private(set) var access: Access = .unknown
    private(set) var isFront = false
    var captured: UIImage?

    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "com.readup.story-camera")
    private var delegate: PhotoDelegate?

    func start() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            access = .granted
        case .notDetermined:
            access = await AVCaptureDevice.requestAccess(for: .video) ? .granted : .denied
        default:
            access = .denied
        }
        guard access == .granted else { return }

        let session = session
        let output = output
        let position: AVCaptureDevice.Position = isFront ? .front : .back
        queue.async {
            session.beginConfiguration()
            session.sessionPreset = .photo
            Self.attachInput(to: session, position: position)
            if session.canAddOutput(output) { session.addOutput(output) }
            session.commitConfiguration()
            if !session.isRunning { session.startRunning() }
        }
    }

    func stop() {
        let session = session
        queue.async { if session.isRunning { session.stopRunning() } }
    }

    func flip() {
        isFront.toggle()
        let session = session
        let position: AVCaptureDevice.Position = isFront ? .front : .back
        queue.async {
            session.beginConfiguration()
            session.inputs.forEach(session.removeInput)
            Self.attachInput(to: session, position: position)
            session.commitConfiguration()
        }
    }

    func capture() {
        guard access == .granted else { return }
        // A câmera frontal entrega a imagem sem espelhar; o usuário espera o que viu.
        let mirrored = isFront
        let delegate = PhotoDelegate(mirrored: mirrored) { [weak self] image in
            self?.captured = image
        }
        self.delegate = delegate
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: delegate)
    }

    private nonisolated static func attachInput(
        to session: AVCaptureSession,
        position: AVCaptureDevice.Position
    ) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }
        session.addInput(input)
    }
}

/// O delegate de captura. Separado porque `AVCapturePhotoCaptureDelegate` é
/// `NSObject` e chega numa fila de fundo.
private final class PhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let mirrored: Bool
    private let completion: @MainActor (UIImage) -> Void

    init(mirrored: Bool, completion: @escaping @MainActor (UIImage) -> Void) {
        self.mirrored = mirrored
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else { return }

        // `image.cgImage ?? image.cgImage!` era um force unwrap disfarçado: quando
        // `cgImage` é nil, o lado direito do `??` estoura no mesmo nil.
        let final: UIImage
        if mirrored, let cgImage = image.cgImage {
            final = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
        } else {
            final = image
        }

        Task { @MainActor in completion(final) }
    }
}

// MARK: - Preview layer

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.layer.session = session
        view.layer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        override var layer: AVCaptureVideoPreviewLayer {
            super.layer as! AVCaptureVideoPreviewLayer
        }
    }
}

#Preview {
    StoryCameraView(story: .preview, card: .constant(StickerTransform())) { _ in }
}
