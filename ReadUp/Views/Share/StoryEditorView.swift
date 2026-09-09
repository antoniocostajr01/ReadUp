import PencilKit
import SwiftUI

/// O editor do story. Figma `10d · Edit`.
///
/// A foto é o fundo; o card é um sticker que o usuário arrasta, pinça e gira. Texto
/// vem de um `TextField` — o teclado do sistema já traz emoji, então não há seletor
/// de emoji a construir — e o desenho é PencilKit, que já traz cores, espessuras e
/// undo. Nenhuma dependência nova.
struct StoryEditorView: View {
    let story: SessionStory
    let photo: UIImage
    /// A posição do card, escolhida ainda na câmera e continuada aqui.
    @Binding var card: StickerTransform

    @Environment(\.dismiss) private var dismiss


    @State private var texts: [TextSticker] = []
    @State private var editingID: TextSticker.ID?
    @State private var isDrawing = false
    @State private var canvas = PKCanvasView()
    @State private var canvasSize: CGSize = .zero
    @FocusState private var isTypingFocused: Bool

    var body: some View {
        ZStack {
            Palette.surfaceNight.ignoresSafeArea()

            GeometryReader { geo in
                composition(in: geo.size)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                    .onAppear { canvasSize = geo.size }
                    .onChange(of: geo.size) { _, size in canvasSize = size }
            }
            .ignoresSafeArea()

            chrome

            if editingID != nil {
                textEditorOverlay
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - A composição
    //
    // É esta mesma hierarquia que o `ImageRenderer` rasteriza no fim. Uma segunda
    // montagem só para exportar divergiria da tela no primeiro retoque.

    /// - Parameter forExport: o `ImageRenderer` não rasteriza um
    ///   `UIViewRepresentable`, então no export o canvas do PencilKit entra já achatado
    ///   em `UIImage`. Sem isso o desenho sumia da imagem publicada.
    @ViewBuilder
    private func composition(in size: CGSize, forExport: Bool = false) -> some View {
        ZStack {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()

            if forExport {
                Image(uiImage: canvas.drawing.image(
                    from: CGRect(origin: .zero, size: size),
                    scale: SessionSummaryShareCard.exportScale
                ))
                .resizable()
                .frame(width: size.width, height: size.height)
            } else {
                DrawingCanvas(canvas: canvas, isActive: isDrawing)
                    .allowsHitTesting(isDrawing)
            }

            cardSticker(in: size)

            ForEach(texts) { sticker in
                textSticker(id: sticker.id, text: sticker.text, color: sticker.color)
            }
        }
    }

    private func cardSticker(in size: CGSize) -> some View {
        // Mesma largura da câmera, para o enquadramento não saltar entre as telas.
        let width = StoryCameraView.cardWidth(in: size)
        return SessionSummaryShareCard(story: story, skin: .sticker)
            .scaleEffect(width / SessionSummaryShareCard.size.width)
            .frame(
                width: width,
                height: width * (SessionSummaryShareCard.size.height / SessionSummaryShareCard.size.width)
            )
            .scaleEffect(card.totalScale)
            .rotationEffect(card.totalRotation)
            .offset(card.totalOffset)
            .gesture(isDrawing ? nil : stickerGesture($card))
    }

    private func textSticker(id: TextSticker.ID, text: String, color: Color) -> some View {
        let transform = transformBinding(for: id)
        return Text(text)
            .textStyle(.field)
            .foregroundStyle(color)
            .shadow(color: .black.opacity(0.5), radius: 6, y: 1)
            .padding(.horizontal, Spacing.sm)
            .scaleEffect(transform.wrappedValue.totalScale)
            .rotationEffect(transform.wrappedValue.totalRotation)
            .offset(transform.wrappedValue.totalOffset)
            .gesture(isDrawing ? nil : stickerGesture(transform))
            // `DragGesture` só engata depois de 10pt, então o toque curto continua
            // chegando aqui e reabre a edição.
            .onTapGesture { editingID = id }
    }

    // MARK: - Chrome

    /// O topo tem dois estados: as ferramentas, ou só o Done.
    ///
    /// Assim que uma ferramenta está ativa — escrevendo ou desenhando — o resto do
    /// menu sai de cena. Ele não faria nada ali (trocar de ferramenta no meio de um
    /// traço não é uma ação que exista) e ainda disputa espaço com a paleta do
    /// PencilKit, que sobe por baixo.
    private var chrome: some View {
        VStack {
            HStack(alignment: .top) {
                if isDrawing {
                    Spacer()
                    doneButton { isDrawing = false }
                } else {
                    PhotoChromeButton(systemImage: "xmark", size: 38, glyphSize: 14) { dismiss() }

                    Spacer()

                    toolRail
                }
            }
            .padding(.horizontal, Spacing.gutterList - Spacing.md)
            .padding(.top, Spacing.sm)

            Spacer()

            // Some no desenho: fica atrás da paleta do PencilKit de qualquer forma.
            if !isDrawing {
                StoryDestinations(image: compose, onDark: true)
                    .padding(.horizontal, Spacing.gutterList)
                    .padding(.bottom, Spacing.xl + Spacing.sm)
            }
        }
        .animation(Motion.fast, value: isDrawing)
    }

    private var toolRail: some View {
        HStack(spacing: Spacing.sm + 2) {
            Button {
                let sticker = TextSticker()
                texts.append(sticker)
                editingID = sticker.id
            } label: {
                Text("Aa")
                    .textStyle(.label)
                    .foregroundStyle(Palette.inkOnArt)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Palette.ink.opacity(0.72)))
                    .overlay(Circle().strokeBorder(Palette.inkOnArt.opacity(0.28), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Localization.SessionSummary.editorAddText.string))

            PhotoChromeButton(systemImage: "scribble", size: 38, glyphSize: 17) {
                isDrawing = true
            }

            PhotoChromeButton(systemImage: "arrow.uturn.backward", size: 38, glyphSize: 16) {
                canvas.undoManager?.undo()
            }
        }
        .padding(.trailing, Spacing.md)
    }

    /// O mesmo Done nos dois modos — o do texto e o do desenho — para sair de uma
    /// ferramenta ser sempre o mesmo gesto no mesmo lugar.
    private func doneButton(_ action: @escaping () -> Void) -> some View {
        Button(Localization.SessionSummary.editorDone.string, action: action)
            .textStyle(.field)
            .foregroundStyle(Palette.inkOnArt)
            .padding(.horizontal, Spacing.md + 2)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
    }

    private var textEditorOverlay: some View {
        ZStack {
            Palette.ink.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { commitEditing() }

            if let editingID {
                TextField(
                    Localization.SessionSummary.editorAddText.string,
                    text: textBinding(for: editingID),
                    axis: .vertical
                )
                .font(.field)
                .foregroundStyle(colorBinding(for: editingID).wrappedValue)
                .multilineTextAlignment(.center)
                .focused($isTypingFocused)
                .padding(.horizontal, Spacing.xl)
                .onAppear { isTypingFocused = true }
            }

            // Ancorado no topo direito da tela e por último no `ZStack`, para ficar
            // acima do campo — encostado nele, o toque no Done era engolido.
            VStack {
                HStack {
                    if let editingID {
                        // `ColorPicker` do sistema: espectro, favoritos e eyedropper
                        // prontos. Nenhuma paleta nossa para manter.
                        ColorPicker("", selection: colorBinding(for: editingID), supportsOpacity: false)
                            .labelsHidden()
                            .padding(.leading, Spacing.md)
                            .accessibilityLabel(Text(Localization.SessionSummary.editorTextColor.string))
                    }

                    Spacer()

                    doneButton { commitEditing() }
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.gutterList - Spacing.md)
            .padding(.top, Spacing.sm)
        }
    }

    /// Endereça o sticker pelo **id**, nunca pelo índice.
    ///
    /// Um `Binding` para `$texts[i]` guarda o índice do momento em que foi criado, e
    /// `commitEditing()` encolhe o array ao descartar stickers vazios — o índice fica
    /// velho e o próximo acesso estoura os limites. Era esse o crash ao fechar o
    /// editor de texto. Por id, o sumiço do elemento vira uma string vazia em vez de
    /// um índice inválido.
    private func textBinding(for id: TextSticker.ID) -> Binding<String> {
        Binding(
            get: { texts.first { $0.id == id }?.text ?? "" },
            set: { newValue in
                guard let index = texts.firstIndex(where: { $0.id == id }) else { return }
                texts[index].text = newValue
            }
        )
    }

    /// O `StickerTransform` do sticker, endereçado por id — mesma razão do `textBinding`:
    /// um índice guardado no `Binding` fica velho assim que o array encolhe.
    private func transformBinding(for id: TextSticker.ID) -> Binding<StickerTransform> {
        Binding(
            get: { texts.first { $0.id == id }?.transform ?? StickerTransform() },
            set: { newValue in
                guard let index = texts.firstIndex(where: { $0.id == id }) else { return }
                texts[index].transform = newValue
            }
        )
    }

    /// A cor do texto, endereçada por id — mesma razão do `textBinding`.
    private func colorBinding(for id: TextSticker.ID) -> Binding<Color> {
        Binding(
            get: { texts.first { $0.id == id }?.color ?? Palette.inkOnArt },
            set: { newValue in
                guard let index = texts.firstIndex(where: { $0.id == id }) else { return }
                texts[index].color = newValue
            }
        )
    }

    private func commitEditing() {
        // Fecha o overlay ANTES de mexer no array: enquanto `editingID` aponta para um
        // sticker, o campo de texto está montado em cima dele.
        editingID = nil
        isTypingFocused = false
        // Um sticker vazio não vira nada: some em vez de virar um alvo invisível.
        texts.removeAll { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    // MARK: - Export

    /// Rasteriza exatamente o que está na tela, a 1080 de largura.
    @MainActor
    private func compose() -> UIImage? {
        guard canvasSize.width > 0 else { return nil }
        let renderer = ImageRenderer(
            content: composition(in: canvasSize, forExport: true)
                .frame(width: canvasSize.width, height: canvasSize.height)
        )
        renderer.scale = 1080 / canvasSize.width
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

private struct TextSticker: Identifiable {
    let id = UUID()
    var text: String = ""
    var color: Color = Palette.inkOnArt
    /// O mesmo `StickerTransform` do card: o texto arrasta, pinça e gira igual.
    ///
    /// Nasce abaixo do card, não no centro: no centro ele caía em cima da capa, e
    /// texto creme sobre uma capa clara não se lê.
    var transform = StickerTransform(offset: CGSize(width: 0, height: 250))
}

// MARK: - PencilKit

/// O canvas de desenho, com o tool picker do sistema.
///
/// PencilKit traz cor, espessura, borracha e undo prontos — é o motivo de o rail de
/// ferramentas ter só um botão de desenho e não uma paleta nossa.
private struct DrawingCanvas: UIViewRepresentable {
    let canvas: PKCanvasView
    let isActive: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        return canvas
    }

    func updateUIView(_ view: PKCanvasView, context: Context) {
        let picker = context.coordinator.toolPicker

        // Só observa uma vez. `updateUIView` roda a cada redesenho, e registrar o
        // observer de novo a cada passagem empilha registros no picker.
        if !context.coordinator.isObserving {
            picker.addObserver(view)
            context.coordinator.isObserving = true
        }

        picker.setVisible(isActive, forFirstResponder: view)

        // Fora do ciclo de layout: mexer no first responder no meio de um update do
        // SwiftUI reentra na atualização da própria view.
        DispatchQueue.main.async {
            guard isActive != view.isFirstResponder else { return }
            if isActive {
                view.becomeFirstResponder()
            } else {
                view.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        let toolPicker = PKToolPicker()
        var isObserving = false
    }
}

#Preview {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1920))
    let placeholder = renderer.image { ctx in
        UIColor(red: 0.30, green: 0.24, blue: 0.18, alpha: 1).setFill()
        ctx.fill(CGRect(origin: .zero, size: CGSize(width: 1080, height: 1920)))
    }
    NavigationStack {
        StoryEditorView(story: .preview, photo: placeholder, card: .constant(StickerTransform()))
    }
}
