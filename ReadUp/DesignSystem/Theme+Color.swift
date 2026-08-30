import SwiftUI

/// Semantic color roles for ReadUp — **Editorial Cream**.
///
/// Views reference roles (`.surface`, `.ink`), never raw values. Roles are named
/// for *meaning*, not placement — so a redesign changes the values here and every
/// screen follows without being touched.
///
/// The values below are lifted 1:1 from the Figma variables on the "Design System"
/// page (file `47zjMbONNMeZJ4WFmEe8MC`, node `34:229`) and from `tokens/colors.css`
/// in the Claude Design project. The two agree exactly; either can be read as the
/// source of truth. Swift name ← Figma variable is noted on each role.
///
/// Three rules the palette encodes, all of them load-bearing:
///
/// 1. **Ink is the brand.** There is no chromatic brand fill. The app's old green is
///    retired. `brand` and `ink` are the same value on purpose.
/// 2. **Amber is the only chromatic colour**, and it appears only on progress fills
///    and week bars (`accentProgress`).
/// 3. **Never a grey.** Anything that reads grey is ink at low alpha (the `line/*`
///    roles) or a step on the cream ramp. All six line roles are literally the same
///    ink at ascending alpha, so retuning `ink` moves every rule with it.
///
/// There is no dark mode. Night is a place, not a theme — the scanner is the only
/// dark screen, and it uses `surfaceNight` explicitly. Every role is therefore a
/// literal value rather than an asset catalog lookup that would flip with the
/// system appearance.
///
/// The role list is mirrored onto `Color` and `ShapeStyle` at the bottom, so tokens
/// work in the leading-dot position (`.foregroundStyle(.inkMuted)`). All three
/// mirrors must stay in sync.
enum Palette {

    // MARK: Surfaces

    /// `surface` — the page itself. Behind everything.
    static let surface = Color(hex: 0xF5F1E8)

    /// `surface/raised` — cards, sheets, rows: anything sitting *on* `surface`.
    /// Separated from `surface` by value alone; cards carry no shadow.
    static let surfaceRaised = Color(hex: 0xFDFBF7)

    /// `surface/fill` — chips, genre tiles, unselected segments.
    static let surfaceFill = Color(hex: 0xEFE9DC)

    /// `surface/control` — circular back/close buttons.
    static let surfaceControl = Color(hex: 0xEBE5D9)

    /// `surface/sunken` — progress tracks, cover placeholders.
    static let surfaceSunken = Color(hex: 0xE4DDD0)

    /// `surface/desk` — the canvas behind device frames.
    static let surfaceDesk = Color(hex: 0xE7E3DB)

    /// `surface/night` — camera and scanner background. The one dark surface.
    static let surfaceNight = Color(hex: 0x26221B)

    /// `chrome/tabbar` — the floating tab bar pill: ink at 94%.
    static let surfaceChrome = ink.opacity(0.94)

    /// A fully-opaque raised surface — overlay chips over camera preview or artwork.
    static let surfaceElevated = surfaceRaised

    // MARK: Ink

    /// `ink` — titles, values, body copy.
    static let ink = Color(hex: 0x171512)

    /// `ink/strong-muted` — intro copy on a light section.
    static let inkStrongMuted = Color(hex: 0x5F584E)

    /// `ink/muted` — subtitles, descriptions.
    static let inkMuted = Color(hex: 0x6D665C)

    /// `ink/soft` — author names, secondary values.
    static let inkSoft = Color(hex: 0x7A7367)

    /// `ink/meta` — metadata, timestamps, "See all".
    static let inkMeta = Color(hex: 0x8A8175)

    /// `ink/faint` — overlines, placeholders.
    static let inkFaint = Color(hex: 0x9A9184)

    /// `ink/fainter` — empty-slot glyphs.
    static let inkFainter = Color(hex: 0xB6ADA0)

    /// `ink/disclosure` — row chevrons.
    static let inkDisclosure = Color(hex: 0xC0B8A8)

    /// `ink/inverse` — text on ink or on night.
    static let inkInverse = Color(hex: 0xF5F1E8)

    /// `ink/on-art` — text over a book cover.
    static let inkOnArt = Color(hex: 0xFBF8F2)

    /// `on-brand` — text and icons on top of a `brand` fill.
    static let onBrand = Color(hex: 0xF5F1E8)

    // MARK: Brand & accent

    /// `brand` — ink IS the brand. Primary buttons, selected chips, tab bar.
    /// Deliberately the same value as `ink`; the app's old green is retired.
    static let brand = ink

    /// `scrim/top` and `scrim/bottom` — the wash over a hero cover, so the title
    /// stays legible whatever the artwork is. Only ever used behind text on art.
    static let scrimTop = Color(hex: 0x26221C)
    static let scrimBottom = Color(hex: 0x14100A)

    /// `accent/progress` — amber. The **only** chromatic colour in the system, and
    /// it appears only on progress fills and week bars. Nowhere else.
    static let accentProgress = Color(hex: 0xF3B54A)

    /// A tinted wash for fills sitting behind `brand` content.
    static let brandSoft = surfaceControl

    // MARK: Status

    /// `status/warning`
    static let warning = Color(hex: 0xB0722A)
    /// `status/warning-surface`
    static let warningSurface = Color(hex: 0xF6E7CC)
    /// `status/warning-ink`
    static let warningInk = Color(hex: 0x5A3B12)
    /// `status/warning-ink-soft`
    static let warningInkSoft = Color(hex: 0x7A5A2C)

    /// `status/danger` — destructive actions and error text. A clay red, not
    /// `Color.red`: a saturated system red is the second chromatic colour the
    /// system does not have.
    static let danger = Color(hex: 0xA8503F)

    // MARK: Lines
    //
    // Always ink at low alpha, never a grey. Expressed as opacities of `ink` rather
    // than six literal hex values so retuning ink moves every rule with it.

    /// `line/divider` — hairline between rows.
    static let divider = ink.opacity(0.09)
    /// `line/divider-strong`
    static let dividerStrong = ink.opacity(0.12)
    /// `line/rule` — vertical rules, stat separators.
    static let rule = ink.opacity(0.14)
    /// `line/border` — outlined tiles, chips.
    static let border = ink.opacity(0.18)
    /// `line/border-strong` — secondary pill buttons.
    static let borderStrong = ink.opacity(0.20)
    /// `line/field` — underlined text field, at rest.
    static let fieldLine = ink.opacity(0.22)
    /// The underlined text field, focused. The jump from `fieldLine` to solid ink
    /// is the entire focus treatment — there is no glow and no label recolour.
    static let fieldLineActive = ink
}

// MARK: - Hex convenience

extension Color {
    /// Builds a color from a `0xRRGGBB` literal, in sRGB.
    ///
    /// The design system is specified in hex and has no dark-mode counterpart, so
    /// the tokens are literals rather than asset-catalog lookups.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Color

extension Color {
    static var surface: Color { Palette.surface }
    static var surfaceRaised: Color { Palette.surfaceRaised }
    static var surfaceFill: Color { Palette.surfaceFill }
    static var surfaceControl: Color { Palette.surfaceControl }
    static var surfaceSunken: Color { Palette.surfaceSunken }
    static var surfaceDesk: Color { Palette.surfaceDesk }
    static var surfaceNight: Color { Palette.surfaceNight }
    static var surfaceChrome: Color { Palette.surfaceChrome }
    static var surfaceElevated: Color { Palette.surfaceElevated }

    static var ink: Color { Palette.ink }
    static var inkStrongMuted: Color { Palette.inkStrongMuted }
    static var inkMuted: Color { Palette.inkMuted }
    static var inkSoft: Color { Palette.inkSoft }
    static var inkMeta: Color { Palette.inkMeta }
    static var inkFaint: Color { Palette.inkFaint }
    static var inkFainter: Color { Palette.inkFainter }
    static var inkDisclosure: Color { Palette.inkDisclosure }
    static var inkInverse: Color { Palette.inkInverse }
    static var inkOnArt: Color { Palette.inkOnArt }
    static var onBrand: Color { Palette.onBrand }

    static var brand: Color { Palette.brand }
    static var brandSoft: Color { Palette.brandSoft }
    static var accentProgress: Color { Palette.accentProgress }

    static var warning: Color { Palette.warning }
    static var warningSurface: Color { Palette.warningSurface }
    static var warningInk: Color { Palette.warningInk }
    static var warningInkSoft: Color { Palette.warningInkSoft }
    static var danger: Color { Palette.danger }

    static var divider: Color { Palette.divider }
    static var dividerStrong: Color { Palette.dividerStrong }
    static var rule: Color { Palette.rule }
    static var border: Color { Palette.border }
    static var borderStrong: Color { Palette.borderStrong }
    static var fieldLine: Color { Palette.fieldLine }
    static var fieldLineActive: Color { Palette.fieldLineActive }
}

// MARK: - ShapeStyle
//
// Lets tokens be written in the leading-dot position, matching how the
// generated asset symbols behave.

extension ShapeStyle where Self == Color {
    static var surface: Color { Palette.surface }
    static var surfaceRaised: Color { Palette.surfaceRaised }
    static var surfaceFill: Color { Palette.surfaceFill }
    static var surfaceControl: Color { Palette.surfaceControl }
    static var surfaceSunken: Color { Palette.surfaceSunken }
    static var surfaceDesk: Color { Palette.surfaceDesk }
    static var surfaceNight: Color { Palette.surfaceNight }
    static var surfaceChrome: Color { Palette.surfaceChrome }
    static var surfaceElevated: Color { Palette.surfaceElevated }

    static var ink: Color { Palette.ink }
    static var inkStrongMuted: Color { Palette.inkStrongMuted }
    static var inkMuted: Color { Palette.inkMuted }
    static var inkSoft: Color { Palette.inkSoft }
    static var inkMeta: Color { Palette.inkMeta }
    static var inkFaint: Color { Palette.inkFaint }
    static var inkFainter: Color { Palette.inkFainter }
    static var inkDisclosure: Color { Palette.inkDisclosure }
    static var inkInverse: Color { Palette.inkInverse }
    static var inkOnArt: Color { Palette.inkOnArt }
    static var onBrand: Color { Palette.onBrand }

    static var brand: Color { Palette.brand }
    static var brandSoft: Color { Palette.brandSoft }
    static var accentProgress: Color { Palette.accentProgress }

    static var warning: Color { Palette.warning }
    static var warningSurface: Color { Palette.warningSurface }
    static var warningInk: Color { Palette.warningInk }
    static var warningInkSoft: Color { Palette.warningInkSoft }
    static var danger: Color { Palette.danger }

    static var divider: Color { Palette.divider }
    static var dividerStrong: Color { Palette.dividerStrong }
    static var rule: Color { Palette.rule }
    static var border: Color { Palette.border }
    static var borderStrong: Color { Palette.borderStrong }
    static var fieldLine: Color { Palette.fieldLine }
    static var fieldLineActive: Color { Palette.fieldLineActive }
}
