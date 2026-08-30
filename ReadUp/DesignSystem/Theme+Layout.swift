import SwiftUI

/// Spacing, radius, elevation, and motion constants — **Editorial Cream**.
///
/// Values from the Figma "Design System" page (`36:229` Spacing, `36:320` Corners,
/// `36:369` Elevation) and `tokens/{spacing,radius,elevation,motion}.css`.
enum Spacing {
    /// 4 — between tightly coupled elements (icon and its label).
    static let xs: CGFloat = 4
    /// 8 — within a component.
    static let sm: CGFloat = 8
    /// 12 — between components in a group.
    static let md: CGFloat = 12
    /// 16 — inside a component group.
    static let lg: CGFloat = 16
    /// 24 — between major sections.
    static let xl: CGFloat = 24
    /// 32 — around isolated hero content.
    static let xxl: CGFloat = 32

    /// 14 — inset used inside cards.
    static let cardInset: CGFloat = 14
    /// 22 — inset used inside bottom sheets.
    static let sheetInset: CGFloat = 22

    // MARK: Gutters
    //
    // Deliberately not one number: auth breathes most.

    /// 20 — list screens (Home, Library, History).
    static let gutterList: CGFloat = 20
    /// 24 — detail screens.
    static let gutterDetail: CGFloat = 24
    /// 28 — auth and onboarding. The widest in the system.
    static let gutterAuth: CGFloat = 28

    // MARK: Component sizes

    /// 246 — the Home hero cover card.
    static let heroHeight: CGFloat = 246
    /// 3 — progress bar over cover art. Deliberately hair-thin.
    static let progressBarHeight: CGFloat = 3
    /// 52 — the circular icon button beside a primary action.
    static let controlCircle: CGFloat = 52
    /// 36×52 — the thumbnail cover in a session row.
    static let coverRowWidth: CGFloat = 36
    static let coverRowHeight: CGFloat = 52
}

/// Corner radii. Covers stay nearly square — a book is a book. Chrome goes fully round.
enum Radius {
    /// 4 — 36–46pt cover thumbnails.
    static let coverSm: CGFloat = 4
    /// 5 — shelf and list covers.
    static let cover: CGFloat = 5
    /// 6 — hero covers on detail screens.
    static let coverLg: CGFloat = 6
    /// 12 — text areas.
    static let field: CGFloat = 12
    /// 14 — outlined action tiles, warning banners.
    static let tile: CGFloat = 14
    /// 16 — stat cards, inline banners.
    static let cardSm: CGFloat = 16
    /// 18 — metric cards, session summary cards.
    static let card: CGFloat = 18
    /// 22 — the Home hero panel.
    static let panel: CGFloat = 22
    /// 28 — bottom sheets.
    static let sheet: CGFloat = 28
    /// Fully rounded. Pills and capsule buttons.
    static let pill: CGFloat = 999

    // MARK: Compatibility
    //
    // The generic t-shirt names the app already calls, remapped onto the scale above.

    /// Deprecated alias — use `.field` or `.tile`.
    static let sm: CGFloat = field
    /// Deprecated alias — use `.tile`.
    static let md: CGFloat = tile
    /// Deprecated alias — use `.cardSm`.
    static let lg: CGFloat = cardSm
    /// Deprecated alias — use `.card`.
    static let xl: CGFloat = card
}

/// Motion. iOS-like: quick out, soft landing.
enum Motion {
    static let easeStandard = Animation.timingCurve(0.32, 0.72, 0, 1)

    /// 0.12 — press feedback.
    static let tap = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.12)
    /// 0.18 — chip select, toggle.
    static let fast = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.18)
    /// 0.26 — sheet, screen push.
    static let base = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.26)
    /// 0.42 — hero cover transition.
    static let slow = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.42)

    /// Tapped pills and cards shrink slightly.
    static let pressScale: CGFloat = 0.97
    /// Tapped text buttons dim.
    static let pressDim: Double = 0.82
    /// Disabled controls.
    static let disabledOpacity: Double = 0.38
}

/// One warm shadow family, for objects that are physically stacked.
///
/// Shadows are brown-black (60,48,30 / 40,30,16), never neutral — a neutral shadow
/// reads grey against cream, and this system never has a grey.
enum Elevation {
    case coverSm, cover, coverLg, coverHero, coverStack, coverTilt

    var color: Color {
        switch self {
        case .coverSm, .cover: Color(hex: 0x3C301E)
        case .coverLg, .coverHero, .coverStack, .coverTilt: Color(hex: 0x281E10)
        }
    }

    var opacity: Double {
        switch self {
        case .coverSm: 0.16
        case .cover: 0.22
        case .coverLg: 0.16
        case .coverHero: 0.26
        case .coverStack: 0.30
        case .coverTilt: 0.24
        }
    }

    /// SwiftUI's shadow radius is roughly half a CSS blur.
    var radius: CGFloat {
        switch self {
        case .coverSm: 6
        case .cover: 10
        case .coverLg: 16
        case .coverHero: 19
        case .coverStack: 22
        case .coverTilt: 15
        }
    }

    var y: CGFloat {
        switch self {
        case .coverSm: 4
        case .cover: 8
        case .coverLg: 14
        case .coverHero: 18
        case .coverStack: 22
        case .coverTilt: 14
        }
    }
}

extension View {

    /// The warm shadow carried by book covers and the device frame.
    func coverShadow(_ level: Elevation = .cover) -> some View {
        shadow(color: level.color.opacity(level.opacity), radius: level.radius, y: level.y)
    }

    /// Intentionally does nothing.
    ///
    /// In Editorial Cream a card is `surfaceRaised` on `surface`, separated by value
    /// alone. Shadow is reserved for things that are *physically stacked* — book
    /// covers and the device — which is what `coverShadow(_:)` is for.
    ///
    /// Kept as a no-op rather than deleted so existing call sites still compile;
    /// remove the calls as those screens are reworked.
    @available(*, deprecated, message: "Cards carry no shadow in Editorial Cream. Remove the call; use coverShadow(_:) for covers.")
    func cardShadow() -> some View { self }
}
