import SwiftUI

// MARK: - Text roles

extension View {

    /// Applies a complete type role: face, size, tracking, and line spacing.
    ///
    /// `.font(_:)` alone only gets you the face and size — SwiftUI's `Font` carries
    /// neither tracking nor line height, and both are specified for every role in
    /// the design system. Use this wherever the content is text.
    func textStyle(_ style: TypeRole) -> some View {
        font(style.font)
            .tracking(style.trackingPoints)
            .lineSpacing(style.lineSpacingPoints)
    }
}

// MARK: - Surfaces

extension View {

    /// The app's card treatment: a continuous rounded rectangle filled with
    /// `surfaceRaised`. No shadow — cards are separated from `surface` by value.
    func cardSurface(radius: CGFloat = Radius.cardSm) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Palette.surfaceRaised)
        )
    }

    /// A recessed fill for chips, tiles, and unselected segments.
    func fillSurface(radius: CGFloat = Radius.tile) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Palette.surfaceFill)
        )
    }
}

// MARK: - Button

/// The system's button. Figma specimens `37:234`.
///
/// Label rule from the design system: *verb phrases naming the outcome — never OK
/// or Submit.*
struct ReadUpButton: View {

    enum Variant {
        /// A solid ink pill. The one primary action on a screen.
        case primary
        /// Transparent with a 20% ink hairline. Providers, alternate actions.
        case secondary
        /// Text only. Navigation away, "skip", "not now".
        case tertiary
        /// Text only, in clay. Destructive.
        case danger
    }

    let title: String
    var variant: Variant = .primary
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    @State private var isPressed = false

    private var isTextOnly: Bool { variant.isTextOnly }

    var body: some View {
        Button(action: action) {
            ReadUpButtonLabel(title: title, variant: variant, isLoading: isLoading)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(opacity)
        .scaleEffect(isPressed && !isTextOnly ? Motion.pressScale : 1)
        .animation(Motion.tap, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { isPressed = $0 }, perform: {})
    }

    private var opacity: Double {
        if !isEnabled || isLoading { return Motion.disabledOpacity }
        if isPressed && isTextOnly { return Motion.pressDim }
        return 1
    }
}

extension ReadUpButton.Variant {
    /// Text-only variants dim on press; filled ones shrink.
    var isTextOnly: Bool { self == .tertiary || self == .danger }

    var height: CGFloat { isTextOnly ? 35 : 54 }

    var foreground: Color {
        switch self {
        case .primary: Palette.onBrand
        case .secondary: Palette.ink
        case .tertiary: Palette.inkMuted
        case .danger: Palette.danger
        }
    }

    var background: Color { self == .primary ? Palette.brand : .clear }

    var borderColor: Color { self == .secondary ? Palette.borderStrong : .clear }
}

/// A pílula desenhada, sem o `Button` em volta.
///
/// Existe porque um `Menu` pede um *label*, não um botão: para um menu nativo sair do
/// próprio botão parecendo um botão do app, os dois precisam desenhar exatamente a
/// mesma coisa. Copiar o estilo no call site funcionaria hoje e divergiria no primeiro
/// retoque do `ReadUpButton`.
struct ReadUpButtonLabel: View {
    let title: String
    var variant: ReadUpButton.Variant = .primary
    var isLoading: Bool = false

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView().tint(variant.foreground)
            } else {
                Text(title)
                    .textStyle(.field)
                    .foregroundStyle(variant.foreground)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: variant.height)
        .background(
            Capsule(style: .continuous).fill(variant.background)
        )
        .overlay(
            Capsule(style: .continuous).strokeBorder(variant.borderColor, lineWidth: 1)
        )
        // A pílula inteira é o alvo, não os glifos do texto.
        //
        // Só a `.primary` tem fill opaco; nas outras o `Capsule` é `.clear` e o
        // contorno é um `strokeBorder` — nenhum dos dois responde a toque, então o
        // botão só engatava quando o dedo caía exatamente na palavra.
        .contentShape(Capsule(style: .continuous))
    }
}

// MARK: - Text field

/// The system's text field. Figma specimens `37:257`.
///
/// Underlined, not boxed. From the design system: *"At rest the line is ink at 22%;
/// focused it goes to solid ink. That value jump is the entire focus treatment."* —
/// so there is deliberately no glow, no label recolour, and no border.
struct UnderlinedField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    /// Marca o campo com o asterisco em âmbar do design (`47:1771`).
    var isRequired: Bool = false
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never

    @FocusState private var isFocused: Bool
    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Group {
                if isRequired {
                    Text(label.uppercased()) + Text(verbatim: " *").foregroundColor(Palette.warning)
                } else {
                    Text(label.uppercased())
                }
            }
            .textStyle(.overline)
            .foregroundStyle(.inkFaint)

            HStack(spacing: Spacing.sm) {
                field
                    .textStyle(.field)
                    .foregroundStyle(.ink)
                    .focused($isFocused)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .font(.iconLabel)
                            .foregroundStyle(.inkFaint)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 9)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isFocused ? Palette.fieldLineActive : Palette.fieldLine)
                    .frame(height: 1)
            }
            .animation(Motion.fast, value: isFocused)
        }
    }

    @ViewBuilder
    private var field: some View {
        // O placeholder precisa ser estilizado à mão: o modificador `.textStyle`
        // não alcança o prompt do TextField.
        let prompt = Text(placeholder).foregroundStyle(Palette.inkFaint)

        if isSecure && !isRevealed {
            SecureField("", text: $text, prompt: prompt)
        } else {
            TextField("", text: $text, prompt: prompt)
        }
    }
}

// MARK: - Chrome chip

/// O botão circular do topo das telas: ‹, ×, •••, ✓. Figma `47:1817`.
///
/// 34pt em `surface/control`. É chrome, não ação primária — nunca leva o ink sólido.
struct ChromeChip: View {
    let systemImage: String
    var isFilled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.iconLabel)
                .foregroundStyle(isFilled ? Palette.onBrand : Palette.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(isFilled ? Palette.brand : Palette.surfaceControl))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chip

/// A selectable pill. Figma specimens `37:243`.
///
/// From the design system: *"Selection is an inversion: cream chip with an 18%
/// border becomes a solid ink fill with cream text at weight 500."*
///
/// Rendered through `ImageRenderer` on the genre onboarding screen, so it must not
/// read anything from `@Environment` beyond what is explicitly injected.
struct GenreChip: View {
    let title: String
    var isSelected: Bool

    var body: some View {
        Text(title)
            .font(isSelected ? TypeRole.label.font : TypeRole.bodySupporting.font)
            .foregroundStyle(isSelected ? Palette.onBrand : Palette.ink)
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(Capsule(style: .continuous).fill(isSelected ? Palette.brand : .clear))
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(isSelected ? Palette.brand : Palette.border, lineWidth: 1)
            )
    }
}

// MARK: - Progress

/// The one place amber appears. Figma specimen `37:271`.
///
/// 3pt tall, 2pt radius, amber on an ink-12% track.
struct ProgressTrack: View {
    /// 0...1.
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Palette.dividerStrong)
                Capsule(style: .continuous)
                    .fill(Palette.accentProgress)
                    .frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 3)
    }
}
