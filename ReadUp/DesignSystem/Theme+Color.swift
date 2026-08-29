import SwiftUI

/// Semantic color roles for ReadUp.
///
/// Views reference roles (`.surface`, `.ink`), never raw values. Roles are named
/// for *meaning*, not placement — so a redesign changes the values in `Palette`
/// below (and in `Assets.xcassets/Colors/`), and every screen follows without
/// being touched.
///
/// Values here are the app's existing palette, so adopting these tokens is a
/// visual no-op. Restyling happens by editing this file and the colorsets.
///
/// The role list is mirrored onto `ShapeStyle` at the bottom, so tokens work in
/// the leading-dot position (`.foregroundStyle(.inkMuted)`) exactly like the
/// asset symbols Xcode generates.
enum Palette {

    // MARK: Surfaces

    /// The page itself. Behind everything.
    static let surface = Color.backgroundPrimary

    /// Cards, sheets, rows — anything sitting *on* `surface`.
    static let surfaceRaised = Color(uiColor: .secondarySystemBackground)

    /// Recessed fills: progress tracks, chips, unselected segments.
    static let surfaceFill = Color(uiColor: .tertiarySystemFill)

    /// Tab bar and other chrome that must read as separate from content.
    static let surfaceChrome = Color.tabBarBackground

    /// A pure, fully-opaque surface — scanner controls, overlay chips. Stays
    /// opaque over camera preview or artwork.
    static let surfaceElevated = Color.componentBackground

    // MARK: Ink

    /// Primary reading text: titles, values, body copy.
    static let ink = Color.mainText

    /// Supporting text: subtitles, captions, metadata.
    static let inkMuted = Color.secundaryLabel

    /// De-emphasized text: placeholders, disabled states.
    static let inkFaint = Color(uiColor: .tertiaryLabel)

    /// Ink inverted against `ink` — content over dark artwork, camera preview,
    /// or a saturated header. Flips with the color scheme, unlike `onBrand`.
    static let inkInverse = Color.componentBackground

    /// Text and icons on top of `brand` or another saturated fill. Always light.
    static let onBrand = Color.white

    // MARK: Brand & status

    /// The brand green. Progress, primary actions, active states.
    static let brand = Color.emphasis

    /// Tinted brand wash for fills sitting behind `brand` content.
    static let brandSoft = Color.weekDayBackground

    /// Destructive actions and error text.
    static let danger = Color.red

    // MARK: Lines

    /// Hairline rules between rows and sections.
    static let divider = Color(uiColor: .separator)
}

// MARK: - Color

extension Color {
    static var surface: Color { Palette.surface }
    static var surfaceRaised: Color { Palette.surfaceRaised }
    static var surfaceFill: Color { Palette.surfaceFill }
    static var surfaceChrome: Color { Palette.surfaceChrome }
    static var surfaceElevated: Color { Palette.surfaceElevated }

    static var ink: Color { Palette.ink }
    static var inkMuted: Color { Palette.inkMuted }
    static var inkFaint: Color { Palette.inkFaint }
    static var inkInverse: Color { Palette.inkInverse }
    static var onBrand: Color { Palette.onBrand }

    static var brand: Color { Palette.brand }
    static var brandSoft: Color { Palette.brandSoft }
    static var danger: Color { Palette.danger }

    static var divider: Color { Palette.divider }
}

// MARK: - ShapeStyle
//
// Lets tokens be written in the leading-dot position, matching how the
// generated asset symbols behave.

extension ShapeStyle where Self == Color {
    static var surface: Color { Palette.surface }
    static var surfaceRaised: Color { Palette.surfaceRaised }
    static var surfaceFill: Color { Palette.surfaceFill }
    static var surfaceChrome: Color { Palette.surfaceChrome }
    static var surfaceElevated: Color { Palette.surfaceElevated }

    static var ink: Color { Palette.ink }
    static var inkMuted: Color { Palette.inkMuted }
    static var inkFaint: Color { Palette.inkFaint }
    static var inkInverse: Color { Palette.inkInverse }
    static var onBrand: Color { Palette.onBrand }

    static var brand: Color { Palette.brand }
    static var brandSoft: Color { Palette.brandSoft }
    static var danger: Color { Palette.danger }

    static var divider: Color { Palette.divider }
}
