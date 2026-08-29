import SwiftUI

/// Named type roles for ReadUp — **Editorial Cream**.
///
/// Two families, one job each: **Instrument Serif** for anything a reader reads as
/// editorial — titles, book names, and *every number* — and **Instrument Sans** for
/// everything the interface says. Italic serif is reserved for author names and is
/// used nowhere else.
///
/// Values are lifted from the 24 text styles on the Figma "Design System" page
/// (file `47zjMbONNMeZJ4WFmEe8MC`, node `34:230`), cross-checked against
/// `tokens/typography.css`.
///
/// ## Faces are addressed by PostScript name
///
/// Google ships Instrument Sans' weights as *separate families* ("Instrument Sans
/// Medium" has family name "Instrument Sans Medium", subfamily "Regular"). So
/// `.weight(.medium)` on a custom font does nothing useful here — the face has to
/// be named outright. `Face` below holds the PostScript names; they must match the
/// filenames registered under `UIAppFonts` in Info.plist.
///
/// ## Tracking and line height are not on `Font`
///
/// SwiftUI's `Font` carries neither, so a role is only half-applied by `.font(_:)`.
/// Use `.textStyle(_:)` (in `Theme+Surfaces.swift`) to apply font, tracking and line
/// spacing together. `TypeRole` below is the full role; the `Font` values are kept
/// as a convenience for the cases where only the face and size matter (SF Symbols,
/// `TextField`, and other places that take a `Font` and nothing else).
enum Face {
    static let serif = "InstrumentSerif-Regular"
    static let serifItalic = "InstrumentSerif-Italic"
    static let sans = "InstrumentSans-Regular"
    static let sansMedium = "InstrumentSans-Medium"
    static let sansSemiBold = "InstrumentSans-SemiBold"
}

/// A complete type role: face, size, line height, and tracking.
///
/// `lineHeight` is a multiplier of the size, exactly as Figma reports it.
/// `tracking` is a **percentage of the size**, also as Figma reports it — Figma's
/// `letterSpacing: -1.5` means −1.5%, not −1.5pt. `.tracking()` takes points, so
/// the conversion happens once, here, in `trackingPoints`.
struct TypeRole {
    let face: String
    let size: CGFloat
    let lineHeight: CGFloat
    /// Percent of `size`, matching Figma's `letterSpacing`.
    let tracking: CGFloat
    /// The `Font.TextStyle` this role scales against under Dynamic Type.
    let relativeTo: Font.TextStyle

    init(
        _ face: String,
        _ size: CGFloat,
        lineHeight: CGFloat = 1,
        tracking: CGFloat = 0,
        relativeTo: Font.TextStyle = .body
    ) {
        self.face = face
        self.size = size
        self.lineHeight = lineHeight
        self.tracking = tracking
        self.relativeTo = relativeTo
    }

    /// `Font.custom(_:size:relativeTo:)`, not `fixedSize:` — Dynamic Type keeps
    /// working, which is why the roles carry a `relativeTo` at all.
    var font: Font { .custom(face, size: size, relativeTo: relativeTo) }

    var trackingPoints: CGFloat { size * tracking / 100 }

    /// SwiftUI's `.lineSpacing` is the gap *between* lines, not the total line box,
    /// so the font's own size has to come off the multiplied height.
    var lineSpacingPoints: CGFloat { max(0, size * lineHeight - size) }
}

// MARK: - Roles

extension TypeRole {

    // MARK: Serif — content and quantity

    /// `Display/Timer` — the running session timer.
    static let displayTimer = TypeRole(Face.serif, 76, tracking: -1.5, relativeTo: .largeTitle)
    /// `Display/Metric XL` — the single large number on a metric card.
    static let displayMetricXL = TypeRole(Face.serif, 48, tracking: -1.5, relativeTo: .largeTitle)
    /// `Display/Hero` — the landing promise. The largest text on any screen.
    static let displayHero = TypeRole(Face.serif, 46, lineHeight: 1.02, tracking: -1.5, relativeTo: .largeTitle)
    /// `Title/XL` — auth screen titles.
    static let titleXL = TypeRole(Face.serif, 40, lineHeight: 1.05, tracking: -1, relativeTo: .largeTitle)
    /// `Title/Screen` — the largest text on a content screen.
    static let titleScreenLarge = TypeRole(Face.serif, 38, lineHeight: 1.05, tracking: -1, relativeTo: .largeTitle)
    /// `Title/Screen SM` — secondary screen titles.
    static let titleScreen = TypeRole(Face.serif, 34, lineHeight: 1.08, tracking: -1, relativeTo: .title)
    /// `Title/Book` — a book title at hero size.
    static let titleBook = TypeRole(Face.serif, 32, lineHeight: 1.10, tracking: -1, relativeTo: .title)
    /// `Title/SM` — major section headings.
    static let titlePrimary = TypeRole(Face.serif, 30, lineHeight: 1.08, tracking: -1, relativeTo: .title)
    /// `Display/Metric` — an inline metric value.
    static let displayMetric = TypeRole(Face.serif, 26, relativeTo: .title2)
    /// `Title/Section` — sub-section headings.
    static let titleSecondary = TypeRole(Face.serif, 24, lineHeight: 1.10, relativeTo: .title2)
    /// `Title/Card` — card titles.
    static let titleCard = TypeRole(Face.serif, 22, lineHeight: 1.12, relativeTo: .title3)
    /// `Title/Shelf` — shelf headings.
    static let titleTertiary = TypeRole(Face.serif, 20, relativeTo: .title3)
    /// `Value/Status` — a status value.
    static let valueStatus = TypeRole(Face.serif, 19, relativeTo: .headline)
    /// `Title/Row` — list row leads.
    static let headingRow = TypeRole(Face.serif, 18, lineHeight: 1.15, relativeTo: .headline)

    // MARK: Italic serif — author names only

    /// `Author/Row` — an author name in a list row.
    static let authorRow = TypeRole(Face.serifItalic, 18, lineHeight: 1.15, relativeTo: .headline)
    /// `Author/Card` — an author name on a card.
    static let authorCard = TypeRole(Face.serifItalic, 22, lineHeight: 1.12, relativeTo: .title3)

    // MARK: Sans — interface

    /// `UI/Field` — field values and the primary button label.
    static let field = TypeRole(Face.sansMedium, 17, lineHeight: 1.2, relativeTo: .body)
    /// `UI/Body` — default reading text.
    static let bodyDefault = TypeRole(Face.sans, 16, lineHeight: 1.5, relativeTo: .body)
    /// `UI/Body SM` — supporting text: subtitles, descriptions.
    static let bodySupporting = TypeRole(Face.sans, 15, lineHeight: 1.5, relativeTo: .subheadline)
    /// `UI/Status Bar` — the status bar clock. The only SemiBold in the system.
    static let statusBar = TypeRole(Face.sansSemiBold, 15, relativeTo: .subheadline)
    /// `UI/Label` — chip and control labels.
    static let label = TypeRole(Face.sansMedium, 14, lineHeight: 1.2, relativeTo: .subheadline)
    /// `UI/Meta` — metadata, timestamps, helper text.
    static let captionDefault = TypeRole(Face.sans, 13, lineHeight: 1.2, relativeTo: .footnote)
    /// `UI/Fine` — fine print.
    static let captionFine = TypeRole(Face.sans, 12, lineHeight: 1.45, relativeTo: .caption)
    /// `UI/Overline` — tracked uppercase labels above metrics and fields.
    /// Tracking is 14% of 11pt ≈ 1.54pt, *not* 14pt.
    static let overline = TypeRole(Face.sans, 11, tracking: 14, relativeTo: .caption2)
}

// MARK: - Font

/// The `Font` half of each role, for call sites that take a `Font` and nothing else
/// (`TextField`, SF Symbols, `.font(_:)` on a container). Where the text is a `Text`,
/// prefer `.textStyle(_:)` — it also applies tracking and line spacing.
extension Font {

    // Serif
    static let displayTimer = TypeRole.displayTimer.font
    static let displayMetricXL = TypeRole.displayMetricXL.font
    static let displayHero = TypeRole.displayHero.font
    static let titleXL = TypeRole.titleXL.font
    static let titleScreenLarge = TypeRole.titleScreenLarge.font
    static let titleScreen = TypeRole.titleScreen.font
    static let titleBook = TypeRole.titleBook.font
    static let titlePrimary = TypeRole.titlePrimary.font
    static let displayMetric = TypeRole.displayMetric.font
    static let titleSecondary = TypeRole.titleSecondary.font
    static let titleCard = TypeRole.titleCard.font
    static let titleTertiary = TypeRole.titleTertiary.font
    static let valueStatus = TypeRole.valueStatus.font
    static let headingRow = TypeRole.headingRow.font

    // Italic serif — authors only
    static let authorRow = TypeRole.authorRow.font
    static let authorCard = TypeRole.authorCard.font

    // Sans
    static let field = TypeRole.field.font
    static let bodyDefault = TypeRole.bodyDefault.font
    static let bodySupporting = TypeRole.bodySupporting.font
    static let statusBar = TypeRole.statusBar.font
    static let labelDefault = TypeRole.label.font
    static let captionDefault = TypeRole.captionDefault.font
    static let captionFine = TypeRole.captionFine.font
    static let overline = TypeRole.overline.font

    // MARK: Compatibility
    //
    // Roles the app already calls that Editorial Cream folds into one of the above.
    // Kept so existing screens compile untouched; prefer the canonical name in new
    // code. `bodySupportingStrong` and `captionStrong` no longer add weight —
    // emphasis in this system comes from the serif/sans split and from ink value,
    // not from bolding a sans face.

    /// Deprecated alias — use `.field`.
    static let bodySupportingStrong = TypeRole.field.font
    /// Deprecated alias — use `.captionDefault`.
    static let captionStrong = TypeRole.captionDefault.font

    // MARK: Icon glyphs
    //
    // SF Symbols are sized by font, so their sizes are type roles too. These stay on
    // the system face — a symbol is not text and must not be set in Instrument Sans.

    /// The large symbol anchoring an empty state.
    static let iconEmptyState = Font.system(size: 52, weight: .light)
    /// A symbol leading a section or inline empty state.
    static let iconSection = Font.system(size: 38, weight: .light)
    /// A symbol inside a card or row.
    static let iconInline = Font.system(size: 18, weight: .regular)
    /// A symbol paired with a label — chips, toolbar buttons.
    static let iconLabel = Font.system(size: 16, weight: .medium)

    // ponytail: symbol weights dropped from semibold/medium to light/regular to sit
    // with a 400-weight serif. The app also uses one-off glyph sizes (88, 84, 56,
    // 44, 42, 36, 34, 20, 13, 9) at a single call site each; left inline until the
    // remaining 17 screens are reworked, which is when a real IconSize scale earns
    // its keep.
}
