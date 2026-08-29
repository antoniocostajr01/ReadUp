import SwiftUI

/// Spacing, radius, and elevation constants.
///
/// Values match what the app already uses, so adopting them changes nothing
/// visually. A redesign retunes the rhythm here once instead of in 80 call sites.
enum Spacing {
    /// 4 — between tightly coupled elements (icon and its label).
    static let xs: CGFloat = 4
    /// 8 — within a component.
    static let sm: CGFloat = 8
    /// 12 — between components in a group.
    static let md: CGFloat = 12
    /// 16 — standard screen gutter.
    static let lg: CGFloat = 16
    /// 24 — between major sections.
    static let xl: CGFloat = 24
    /// 32 — around isolated hero content.
    static let xxl: CGFloat = 32

    /// Inset used inside cards. Deliberately 14 — between `md` and `lg` — because
    /// that is the app's established card padding.
    static let cardInset: CGFloat = 14
}

enum Radius {
    /// 8 — chips, small badges.
    static let sm: CGFloat = 8
    /// 12 — the default. Most cards and fields.
    static let md: CGFloat = 12
    /// 14 — cards using `Spacing.cardInset`.
    static let lg: CGFloat = 14
    /// 16 — large panels.
    static let xl: CGFloat = 16
    /// Fully rounded. Pills and capsule buttons.
    static let pill: CGFloat = 50
}

/// Card elevation. One shadow, applied consistently.
extension View {
    func cardShadow() -> some View {
        shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
