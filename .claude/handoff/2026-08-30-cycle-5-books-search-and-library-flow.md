# Cycle 5 — Books search and library flow

Executed 2026-08-30 on branch `feat/books-search-library-flow`, five commits off `main`
(`80d09dc`). Plan: `~/.claude/plans/bro-we-need-to-frolicking-sifakis.md` (session plan,
not a repository file). Figma section `47:1326` "Books Search and Library Flow", marked
Ready to Dev. iOS repository only — `ReadUpBackend` was not touched.

## What shipped

The whole add-book flow moved onto Editorial Cream — details, search, manual entry,
scanner — plus the two behaviours the canvas asks for in Portuguese annotations: the
book detail *grows out of the cover you tapped*, and every add path ends on an
achievement screen.

## Files touched

**`5ae8673` — details, the grow transition, the celebration.**

- `Views/BookDetailsSheet.swift` — rewritten to `47:1813` / `47:1849`. Hero cover,
  serif title with italic author, the pages/current/done stat row on `Palette.rule`
  hairlines, description, status pill, one primary action. The `NavigationStack` and
  `navigationTitle` are gone: the screen draws its own chrome chips.
- `Views/BookAddedView.swift` (new) — `47:1603` / `47:1588`. Cover springs in at 0.6
  scale, caption follows, one `.sensoryFeedback(.success, …)`.
- `Views/Library.swift` — `@Namespace coverNamespace`, `.matchedTransitionSource` on
  each shelf cover, `.navigationTransition(.zoom(…))` + `.presentationDetents([.large])`
  on the detail sheet.
- `Components/BookCoverView.swift` — the typeset placeholder (`47:1822`).
- `Components/StatusPill.swift` (new), `DesignSystem/Theme+Surfaces.swift` —
  `ChromeChip` added beside `ReadUpButton`/`UnderlinedField`.
- `ViewModels/LibraryStore.swift` — `addBook` and `createManualBook` return `Book?`.
- `Views/SearchBookDetails.swift`, `ViewModels/SearchBookDetailsViewModel.swift` — deleted.

**`ba4f71d` — search.** `Views/Search.swift` rewritten to `47:1664` / `47:1714`;
`Localizations/Localization+Search.swift`, `Localizable.xcstrings`.

**`5e6daf7` — manual entry.** `Views/BookFormView.swift` rewritten to `47:1754`;
`ViewModels/BookFormViewModel.swift` gained `startingPageText`;
`UnderlinedField` gained `isRequired`.

**`ac2d2ad` — scanner.** `Views/Scanner/ISBNScanView.swift` rewritten to `29:142`,
`Views/Scanner/ScannedBookSheet.swift` (new) covering `47:1378` and `47:1414`,
`ViewModels/ISBNScannerViewModel.swift` (`addAll` returns `[Book]`).

**Library polish + dead code.** `Library.swift`'s add-options sheet moved onto tokens;
`Views/BookDetails.swift` and `ViewModels/BookDetailsViewModel.swift` deleted — a second
superseded full-screen detail with no call sites.

`Localizable.xcstrings`: 240 → 270 keys, every one translated in en and pt-BR.

## Decisions made during implementation

- **The detail is a screen swapped inside a `ZStack`, not a sheet, and the cover flies
  by `matchedGeometryEffect`.** This replaced a first attempt that presented the detail
  as a `.sheet` with `.navigationTransition(.zoom(…))`; the user rejected it on both
  counts — it read as a modal, and the zoom expands the tapped cover into the *whole*
  destination rather than moving it to the hero slot, which is not what the reference
  recording shows. Frame 02 of that recording has the cover already at hero size and
  position while the grid behind is still visible and fading: one element moves, the
  rest cross-fades. That is `matchedGeometryEffect`, and it only works inside a single
  view hierarchy — hence the `ZStack` with `if selectedBook != nil` swapping the lower
  layer, which is what the user proposed.
- **`matchedGeometryEffect` was then replaced by a genuinely persistent layer.** The
  effect does not move a view: there are two covers and SwiftUI interpolates the frame
  while the contents cross-fade, so a cover that has loaded in one and not the other pops
  mid-flight. `Components/HeroCover.swift` now holds the alternative — covers publish
  their frames into a `CoverFrameStore` (a plain class, so writing to it during a scroll
  invalidates nothing), and on tap the tapped cover is promoted into `FlyingCover`, a
  single view in the front layer of the `ZStack` that never leaves the screen. The cover
  in the list hides while its book is in flight. The hero in `BookDetailsView` is now
  just a reserved empty space that reports where it landed.
- **The flight animates, the scroll does not.** The same `onHeroPlacement` callback fires
  for both, so the host tracks an `isFlying` flag: during the flight the placement change
  is wrapped in `Motion.heroFlight`, and afterwards it is assigned straight through.
  Springing on scroll would leave the cover dragging behind the finger.
- **The scroll fade shortened to 150pt.** The flying cover lives above the detail's own
  chrome and is not clipped by its `ScrollView`, so it has to be gone before it reaches
  the nav chips. This is the weak seam in the approach — a cover in a front layer has no
  z-order relationship with the screen underneath it.
- **The tab bar is hidden by `.toolbar(selectedBook == nil ? .visible : .hidden, for: .tabBar)`.**
  The detail is full-bleed; a floating iOS 26 tab bar over its primary action would be
  wrong. Reactive toolbar visibility without a navigation push is the part of this change
  least certain to behave, and it has not been seen running.
- **`BookDetailsView` reads the library book back out of the store on every render.**
  `Source` carries a copy taken at tap time. While the detail was a sheet, editing
  dismissed it and the stale copy died with it; now the screen stays mounted underneath
  the edit form, so without the re-read the title and page count would revert the moment
  the form closed.
- **Scroll collapse is scale + opacity on the hero, not a pinned header.** Driven off
  `.onScrollGeometryChange`; the frame is shrunk in step so the layout does not leave a
  320pt hole where the cover was.
- **The typeset cover placeholder is sized by ratio, not by a `TypeRole`.** The same
  placeholder serves the 224pt hero, the 151pt scanner cover and a 72pt shelf card; a
  fixed role covers none of the three. Ratios are taken from `47:1822` and commented.
- **Search rows show "no cover" rather than the typeset placeholder.** At 46×66 the
  typeset version is unreadable. The Figma frame agrees — `47:1695` is a
  `surface/sunken` block with the words in it.
- **The meta line drops the year.** `47:1682` reads "Yuval Noah Harari · 2014 · 443 p.",
  but `SearchBook` carries no publication year and the backend does not send one. The
  line renders "author · N p." rather than inventing a value.
- **Starting page is written in a second call.** `CreateBookPayload` has no `progress`
  field and `UpdateBookPayload` does, so a manually created book that starts past page 1
  is created and then updated. Only fires when the value is not 1. Adding `progress` to
  the create payload would have needed a backend change and would fail silently if the
  API ignored it.
- **The scanner keeps its batch model.** `47:1378` and `47:1414` are reachable by
  tapping a scanned row, which is what makes all three scanner frames fit the flow that
  already existed instead of replacing it.
- **The `+` on a search result adds with `.iWantToRead` and skips the detail.** The
  frame gives the row an add button *and* makes the row tappable; the button has to mean
  "add it now" or it is just a second way to open the detail.

## What was verified

`xcodebuild -scheme ReadUp -destination 'generic/platform=iOS Simulator' build` after
each of the four commits and after the Library polish — `** BUILD SUCCEEDED **` every
time, no errors.

The two design-system greps from `CLAUDE.md`, run after each commit, both empty:

```
grep -rn 'Color(uiColor:' ReadUp --include='*.swift' | grep -v 'DesignSystem/'
grep -rn '\.secundaryLabel\|\.emphasis\b\|\.mainText\|\.backgroundPrimary' ReadUp --include='*.swift' | grep -v 'DesignSystem/'
```

The app was installed and launched on the "Iphone iOS 18.4" simulator
(`72FA731D`, iOS 26.5): it boots, auto-signs in as `dev@readup.test`, and renders Home
with a real library. No crash on launch.

**Not verified:** none of the new screens was actually walked. This machine has no way
to drive the simulator's UI from the command line — `idb` and `cliclick` are not
installed and `osascript` has no assistive access — so Library, Search, the details
screen, the celebration and the scanner sheets have been compiled and reached the same
binary, but never seen on screen. The zoom transition, the celebration spring and the
pt-BR pass are all unconfirmed.

## Open items

- **Walk the flow by hand** on the simulator against `dev@readup.test`, in both
  languages — this is the one thing the cycle could not do for itself. In
  particular the scanner needs a device: `DataScannerViewController` is unavailable in
  the simulator, so the 08 / 08b / 08c sheets have never been rendered with real data.
- `47:1714`'s dashed placeholder is drawn at 104×138; the frame's exact size was read
  from the screenshot, not from `get_design_context`.
- The stat row shows "—" for a search result with no page count. The design has no state
  for that; it was the honest option and may want a real treatment.
- `Localization.Generic.done` lost its last call site when Library stopped wrapping
  `Search` in a `NavigationStack`. Left in place; it is one key.
