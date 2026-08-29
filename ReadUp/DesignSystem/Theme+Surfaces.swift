import SwiftUI

extension View {

    /// The app's card treatment: a continuous rounded rectangle filled with
    /// `surfaceRaised`.
    ///
    /// This is the single most repeated pattern in the codebase — it appeared
    /// inline in ~18 places before it lived here.
    func cardSurface(radius: CGFloat = Radius.lg) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Palette.surfaceRaised)
        )
    }

    /// A recessed fill for progress tracks, chips, and unselected segments.
    func fillSurface(radius: CGFloat = Radius.md) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Palette.surfaceFill)
        )
    }
}
