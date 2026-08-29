import SwiftUI

/// Named type roles for ReadUp.
///
/// Roles are named for the job the text does, not its size — so a redesign
/// retunes the scale here and every screen follows. Values match what the app
/// already renders, so adopting these tokens is a visual no-op.
///
/// Fixed sizes are used only where the app already relies on one (the session
/// timer, auth titles, empty-state glyphs); everything else is built on a
/// semantic text style so Dynamic Type keeps working.
extension Font {

    // MARK: Display

    /// The running session timer. Rounded so digits read as a clock.
    static let displayTimer = Font.system(size: 52, weight: .bold, design: .rounded)

    /// The single large number on a metric card.
    static let displayMetric = Font.system(size: 38, weight: .bold)

    // MARK: Titles

    /// Landing and sign-in titles — the largest text on a screen.
    static let titleScreenLarge = Font.system(size: 34, weight: .bold)

    /// Secondary auth screens (create account, password reset).
    static let titleScreen = Font.system(size: 30, weight: .bold)

    /// Major section headings.
    static let titlePrimary = Font.system(.title, weight: .bold)

    /// Card titles and prominent labels.
    static let titleSecondary = Font.system(.title2, weight: .bold)

    /// Sub-section headings.
    static let titleTertiary = Font.system(.title3, weight: .semibold)

    // MARK: Body

    /// Emphasized inline text — list row leads.
    static let headingRow = Font.system(.headline, weight: .semibold)

    /// Default reading text.
    static let bodyDefault = Font.body

    /// Supporting text: subtitles, metadata. The most-used role in the app.
    static let bodySupporting = Font.subheadline

    /// Supporting text needing weight — active values, selected states.
    static let bodySupportingStrong = Font.subheadline.weight(.semibold)

    // MARK: Small

    // Named `caption*` rather than `caption` on purpose: `Font.caption` is a
    // SwiftUI built-in, and shadowing it here would silently retarget every
    // existing `.font(.caption)` call site.

    /// Captions, timestamps, helper text.
    static let captionDefault = Font.footnote

    /// Captions carrying emphasis — badges, counts.
    static let captionStrong = Font.footnote.weight(.semibold)

    /// Tracked labels above metrics.
    static let overline = Font.system(.caption, weight: .semibold)

    // MARK: Icon glyphs
    //
    // SF Symbols are sized by font, so their sizes are type roles too.

    /// The large symbol anchoring an empty state.
    static let iconEmptyState = Font.system(size: 52, weight: .regular)

    /// A symbol leading a section or inline empty state.
    static let iconSection = Font.system(size: 38, weight: .medium)

    /// A symbol inside a card or row.
    static let iconInline = Font.system(size: 18, weight: .medium)

    /// A symbol paired with a label — chips, toolbar buttons.
    static let iconLabel = Font.system(size: 16, weight: .semibold)

    // ponytail: the app also uses one-off glyph sizes (88, 84, 56, 44, 42, 36,
    // 34, 20, 13, 9) at a single call site each. Left inline deliberately —
    // single-use constants are not shared tokens, and the Editorial Cream
    // wireframes will redefine this scale anyway. Collapse them into a proper
    // IconSize scale when that design lands.
}
