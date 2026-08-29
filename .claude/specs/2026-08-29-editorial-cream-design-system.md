# Editorial Cream — Design System

**Date:** 2026-08-29
**Status:** approved, design system + auth flow implemented; remaining screens deferred
**Repository affected:** `ReadUp` (iOS app)

---

## Problem

The app shipped with the native Xcode starting palette: a green brand colour, SF Pro
everywhere, boxed text fields, shadowed cards, and a token layer (`Palette`, added in
`c74fa2f`) whose values were still asset-catalog lookups tuned for light/dark parity
against system semantic colours. None of it said "reading" — a serif is the one
typographic signal a reading app can make for free, and the app used none. There was
also no type hierarchy distinguishing content (a book's title, a page count) from
interface (a button label, a field placeholder); everything was one weight of one
system font.

## The decision: Editorial Cream

Source of truth: the Figma file `47zjMbONNMeZJ4WFmEe8MC`, page "Design System"
(`34:229`, one frame `34:230` "ReadUp — Editorial Cream") — Colour `34:235`
(Surfaces `34:239`, Ink `34:277`, Brand & accent `34:325`, Status `34:343`,
Lines `34:371`), Typography `35:229` (Serif `35:233`, Italic `35:301`, Sans `35:314`),
Spacing `36:229`, Corners `36:320`, Elevation `36:369`, Components `37:229`
(specimens `37:233`: Buttons `37:234`, Chips `37:243`, Text fields `37:257`,
Progress `37:271`, Warning banner `37:290`, Chrome `37:296`). 31 colour variables,
24 text styles. The Claude Design project `f7b730f5-68da-495c-af46-51e4a19b0003`
(`tokens/*.css`) agrees with the Figma variables exactly; the Figma page additionally
carries the prose rationale per section and the measured component specimens, which
the CSS does not.

The masthead states the whole direction in one line: *"Paper, not glass. Every
surface is a shade of cream; every line is ink at low alpha; every shadow is warm
brown-black. The book cover is the only saturated thing on screen. The interface
recedes."*

Four load-bearing rules follow from that, and each one earns its place:

**1. Ink is the brand — no chromatic brand fill; the green is retired.**
*"There is no coloured brand fill — ink IS the brand."* `Palette.brand` and
`Palette.ink` are the same literal value on purpose (`Theme+Color.swift`). This buys
one thing above all: a button, a selected chip, and the tab bar all read as "the same
material" as body text, so nothing on screen competes with a book cover for
attention. A green CTA next to a cover photo is two saturated things fighting; ink
next to a cover is one.

**2. Amber is the sole chromatic colour, reserved for progress.**
`Palette.accentProgress` (`#F3B54A`) appears in exactly one place: `ProgressTrack`
and week bars. Scarcity is what makes it legible — if amber also lived on buttons or
badges, "progress" would stop being a color a user recognizes at a glance and become
just decoration. One accent, one meaning, everywhere in the app.

**3. Never a grey — every apparent grey is ink at 9–22% alpha, or a cream step.**
*"Never a grey: if something looks grey it is ink at 9–22% alpha, or a cream step."*
A neutral system grey has no relationship to the warm cream surfaces around it — it
reads as a foreign material dropped onto paper. Ink-at-alpha is the same pigment as
the body text, diluted, so a divider or a placeholder looks like a lighter mark of
the same ink rather than a different substance. All six `line/*` roles in
`Theme+Color.swift` are expressed as `ink.opacity(_:)` rather than six independent
hex values for exactly this reason: retuning `ink` retunes every line in the system
in one edit.

**4. No dark mode — night is a place, not a theme.**
The scanner screen is the only dark surface (`Palette.surfaceNight`), used
explicitly, not as a system-driven variant. Every other role in `Palette` is a
literal value rather than an asset-catalog lookup, so the app does not adapt to
Settings → Appearance at all. The cost accepted here is real: no automatic contrast
boost, no free adaptation for users who prefer dark interfaces system-wide, and any
future dark treatment would have to be designed as its own set of literals, not
inherited for free from semantic system colours. That was accepted because Editorial
Cream's identity is the cream surface itself — a "dark mode" version of a paper
aesthetic is not a lighting variant, it's a different app, and building one
speculatively before it's asked for would be exactly the kind of unrequested
flexibility this system otherwise avoids (see "Never a grey" above: the whole point
is one warm, consistent material).

**Cards carry no shadow.** *"A card is `surface/raised` on `surface`, separated by
value alone."* Shadow is reserved for things that are physically stacked in the real
world — book covers and the device frame — and shadows in this system are warm
brown-black (`#3C301E` / `#281E10` in `Theme+Layout.swift`'s `Elevation`), never
neutral, for the same reason line roles are ink-at-alpha rather than grey: a neutral
shadow under a warm cream card reads as a foreign material.

**Two type families, one job each.** Instrument Serif carries content and *every
number* (titles, book names, metric values, the session timer) — anything a reader
reads as editorial. Instrument Sans carries everything the interface says (buttons,
fields, labels). Italic serif is reserved for author names and used nowhere else.
The split gives the eye a free signal for "this is the book talking" vs. "this is
the app talking" without any extra chrome.

## Evidence: what made this cheap

A grep for direct colour-asset references outside `DesignSystem/` returned **zero
hits** before this cycle (verified against `ae83d52`, the commit this cycle branched
from):

```sh
grep -rn 'Color(uiColor:' ReadUp --include='*.swift' | grep -v 'DesignSystem/'
grep -rn '\.secundaryLabel\|\.emphasis\b\|\.mainText\|\.backgroundPrimary' \
     ReadUp --include='*.swift' | grep -v 'DesignSystem/'
```

Every screen already routed through semantic `Palette`/`Font`/`Spacing`/`Radius`
roles, established in commit `c74fa2f` ("Add semantic design system and migrate all
views onto it"). That meant adopting the whole Editorial Cream direction was an edit
to four files — `Theme+Color.swift`, `Theme+Typography.swift`, `Theme+Layout.swift`,
`Theme+Surfaces.swift` — plus the backing colorsets, and all 21 screens restyled
without a single one being touched (commit `81312d4`; `xcodebuild` succeeded with
zero changes under `Views/`). This is the strongest argument in this document for why
the token layer was worth building in the first place: the redesign's entire cost was
proportional to the number of *roles*, not the number of *screens*.

## Decisions taken during this cycle, with reasoning

1. **Guest mode kept.** The Figma Welcome frame (`24:82`) shows only two buttons, but
   the app's previous carousel's final button was the only entry point into
   `authManager.enterGuestMode()`. A third, tertiary "Continue as guest" action is
   kept on the rebuilt Welcome screen so `GuestGate.swift`, `SignInRequiredView`
   (used by `TabBar.swift`'s `gated(_:icon:title:)`), and the guest-only Search tab
   stay reachable. Design fidelity was traded for a working feature that has no other
   entry point in the app.

2. **`GenrePhysicsScene` kept.** Figma's Onboarding genres frame (`26:134`) shows a
   static wrapped chip grid. The app's existing `GenrePhysicsScene.swift` drops chips
   with SpriteKit gravity — a playful moment judged worth keeping over strict fidelity
   to the static mock. Only the chip texture (`GenreChip` in `Theme+Surfaces.swift`)
   was restyled to the new tokens. The known cost is recorded rather than hidden: the
   chips render as bitmaps inside the physics scene (confirmed by `GenreChip`'s doc
   comment — "Rendered through `ImageRenderer`... so it must not read anything from
   `@Environment` beyond what is explicitly injected"), so those chips carry no
   VoiceOver label and do not respond to Dynamic Type.

3. **Fonts bundled.** Instrument Serif and Instrument Sans are Google Fonts under the
   SIL Open Font License. Five `.ttf` faces are committed under
   `ReadUp/Resources/Fonts/` and registered via `UIAppFonts` in `Info.plist`
   (confirmed present). The non-obvious part: Google ships each Instrument Sans
   weight as its *own* family — "Instrument Sans Medium" has family name "Instrument
   Sans Medium", subfamily "Regular" — so SwiftUI's `.weight()` modifier cannot reach
   them. `Face` in `Theme+Typography.swift` addresses each face by PostScript name
   instead (`InstrumentSans-Medium`, `InstrumentSans-SemiBold`, etc.), and those names
   must match the filenames registered under `UIAppFonts`.

4. **Create account keeps Confirm password and the terms gate.** Figma's Create
   account frame (`32:172`) shows three fields. Dropping a password-confirmation field
   and a terms-of-service acceptance step is a product and legal decision, not a
   visual one, and out of scope for a design-system cycle — so both are kept. Only
   `lastName` was dropped from the form.

## Two implementation facts worth recording as design constraints

- **SwiftUI's `Font` carries neither tracking nor line height**, and every role in
  the Figma type scale specifies both. `TypeRole` (`Theme+Typography.swift`) is the
  full role — face, size, line height, tracking — and `.textStyle(_:)`
  (`Theme+Surfaces.swift`) applies all three together. A plain `Font` constant would
  silently drop two thirds of the spec.

- **Figma reports `letterSpacing` as a percent of font size, not points.** The
  overline role's letter-spacing value of `14` means 0.14em, not 14pt — at an 11pt
  size that's ≈1.54pt. This cross-checks exactly against `--track-overline: 0.14em`
  in the CSS tokens. `TypeRole.trackingPoints` (`size * tracking / 100`) is the one
  place this conversion happens; treating `14` as literal points would blow the
  overline apart (it would render at over 100% of its own size in extra spacing).

## Deferred

`WarningBanner` (Figma `37:290`) and `StatusControl` (Figma `37:282`) are specified
with full prose and measurements on the Design System page but were not built this
cycle — they belong to screens whose layouts were not reworked. Recorded here so the
next cycle that touches those screens does not have to re-derive their specs from
Figma from scratch.

## Out of scope

The other 17 Figma "Screens" artboards (of 21 total). They inherit the palette and
type automatically the moment they render — every call site already routes through
`Palette`/`TypeRole`/`Spacing`/`Radius` — but keep their current layouts until a
future cycle reworks them individually.
