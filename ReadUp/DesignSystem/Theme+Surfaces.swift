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

    private var height: CGFloat { variant == .tertiary || variant == .danger ? 35 : 54 }

    private var foreground: Color {
        switch variant {
        case .primary: Palette.onBrand
        case .secondary: Palette.ink
        case .tertiary: Palette.inkMuted
        case .danger: Palette.danger
        }
    }

    private var background: Color {
        variant == .primary ? Palette.brand : .clear
    }

    private var borderColor: Color {
        variant == .secondary ? Palette.borderStrong : .clear
    }

    /// Text-only variants dim on press; filled ones shrink.
    private var isTextOnly: Bool { variant == .tertiary || variant == .danger }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(foreground)
                } else {
                    Text(title)
                        .textStyle(.field)
                        .foregroundStyle(foreground)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                Capsule(style: .continuous).fill(background)
            )
            .overlay(
                Capsule(style: .continuous).strokeBorder(borderColor, lineWidth: 1)
            )
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
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never

    @FocusState private var isFocused: Bool
    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label.uppercased())
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
