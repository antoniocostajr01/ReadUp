# Cycle 6 — New home with history

Executed 2026-09-06 on branch `feat/books-search-library-flow` (the branch cycle 5 left
open; **nothing was committed** — the changes sit in the working tree). Plan:
`~/.claude/plans/implementa-a-section-new-glistening-forest.md` (session plan, not a
repository file). Figma section `71:371` "New home with history". iOS repository only —
`ReadUpBackend` was not touched.

## What shipped

Home stopped hiding books. It showed exactly one — `readingBooks.first` — so a reader
with three books in progress could act on one of them and reach the other two only
through Library. It is now a horizontal rail of every in-progress book, and the primary
button acts on the card you are looking at. The two mismatched stat tiles became one
three-metric card, and History was rebuilt from a pre-redesign list into the artboard.

Scope was set with the user before starting: **Home + History**. `10 · Session summary`
was left alone — it already matches its mock.

## Files touched

**Design system.** `DesignSystem/Theme+Layout.swift` — six new `Spacing` members
(`readingCardWidth/Height` 232×336, `coverHistoryWidth/Height` 44×64,
`weekBarMaxHeight` 88, `weekBarEmptyHeight` 12), following the existing
`heroHeight`/`coverShelfWidth` naming.

**Store.** `ViewModels/LibraryStore.swift` — `assemble(_:books:)` now sorts by
`timesTamp` descending.

**View model.** `ViewModels/HomeViewModel.swift` — additive only:
`averageMinutesPerDay`, `pagesThisWeek`, `sessionsThisWeek`, `minutesByWeekday`,
`weekdayLabels`, `historyTotals`, `durationFormatted`, `sessionsByPeriod`,
`sessionMeta`. `averageTimePerDayFormatted` was left untouched because `Profile.swift`
still calls it.

**Components.**
- `Components/CurrentlyReadingCard.swift` — gained `width`/`height`; `nil` width keeps
  the original full-bleed hero, so no existing call site changed. Its cover placeholder
  now delegates to `BookCoverView`'s typeset one.
- `Components/RecentActivityRow.swift` — gained `coverWidth`, `coverHeight`,
  `titleStyle`, `showsPagesCaption`. One row serves both screens.
- `Components/WeekBars.swift` (new) — the seven amber bars.
- `Components/WeeklyHistory.swift`, `Components/SessionDetails.swift` — **deleted**.

**Screens.** `Views/Home.swift` and `Views/History.swift` rewritten.

**Localisation.** `Localization+Components.swift`, `+Home.swift`, `+History.swift`;
`Localizable.xcstrings` 279 → 285 keys, all 15 new/changed keys translated in en and
pt-BR.

**Figma.** Artboard `70:387`'s background was bound to `surface/desk` (`#E7E3DB`, the
canvas colour) instead of `surface` (`#F5F1E8`). The code was always right; the mock was
wrong. Rebound to `surface`.

## Decisions made during implementation

- **The button acts on the visible card, not on `readingBooks.first`.** `activeBookID`
  drives both `.scrollPosition(id:)` and the button's target. Without this the carousel
  would be decorative — you could swipe to a book and still start a session on a
  different one. Verified on device: swiping to 1984 and tapping the button opened a
  1984 session.
- **The card is 232×336, not the artboard's 232×220.** At 220 it read as a landscape
  banner with a cropped cover, and the point of the rail is that you recognise the book
  by its cover. The height is the shelf cover's own ratio (72×104) applied to the card
  width, so the card is proportioned like every other book in the app. The artboard is
  now the thing that disagrees; it was not updated.
- **The active card is centred, not leading-aligned.** The first pass pinned the rail
  with `anchor: .leading` and a plain horizontal padding; on device it read badly — the
  "current" card sat against the left edge and the dot indicator felt disconnected from
  it. It now uses `anchor: .center` plus
  `.contentMargins(.horizontal, (width - cardWidth) / 2, for: .scrollContent)`, the
  width coming from `onGeometryChange`. The margin is what lets the *first* and *last*
  cards reach the middle instead of stopping at the edge; without it only the interior
  cards could centre. The dot indicator is centred under the card it tracks.
- **`syncActiveBook()` re-seeds the id when the library reloads.** A stored id whose book
  has left `.reading` would otherwise strand the button. Runs on `onAppear` and on
  `onChange(of: readingBooks.map(\.id))` — the id array, not the array of `Book`, so a
  progress edit doesn't churn it.
- **The carousel card drops to `.titleCard` (serif 22) and `.captionDefault`.** The
  full-bleed hero uses `.titlePrimary` (serif 30); at 232pt wide that wraps the first
  long title. `width == nil` selects between them, so the hero is unchanged.
- **Home's `VStack` lost its blanket horizontal padding.** The rail has to bleed
  edge-to-edge, so each section now pads itself and the rail pads its inner `HStack` —
  the pattern `Library.statusRail` and `Search`'s genre shelf already use.
- **The `+` add-book button was removed** per the mock, on the user's decision. Search is
  still reachable from Library's `+`. `Localization.Home.addBook` and
  `alertNoBooksTitle`/`alertNoBooksMessage` are now call-site-less; left in place rather
  than deleted, as cycle 5 did with `Generic.done`.
- **Week-bar heights scale against the week's own peak, not a fixed goal.** The tallest
  day always reaches the ceiling, so the silhouette compares days to each other. A day
  with no reading is a 12pt stub in `surface/sunken`, not absent — that is what makes the
  week readable as a shape.
- **History draws its own `ChromeChip` back button.** The 38pt Instrument Serif title is
  content, so the nav bar is hidden — and the artboard shows no back affordance at all.
  A pushed screen reachable only by edge-swipe is not acceptable, so the chip was added
  against the mock, matching `BookDetailsView`'s precedent from cycle 5.
- **Session rows match the mock exactly (44×64, two-line delta) via parameters, not a
  second component.** The user chose exact fidelity over reusing Home's smaller row; a
  parameterised `RecentActivityRow` delivers the mock's pixels without a near-identical
  twin to keep in sync.
- **Pluralisation is a singular/plural key pair chosen in Swift, not an `.xcstrings`
  plural variation.** The first run rendered "1 days" and "1 sessions". A catalogue
  plural variation needs the number *inside* the string, but the stat card styles the
  number (serif 30) and the unit (sans 13) differently, so they cannot be one string.
  Marked `ponytail:` in `Localization+Components.swift`: this covers `one`/`other`, which
  is en and pt-BR; a language with more plural forms would need the catalogue.
- **`Palette.divider` on a `Rectangle`, not `Divider()`, between stat columns.**
  `Divider` is a list hairline; a fixed 1×48 separator is a rectangle.
- **Fixed the dead arithmetic** at the old `History.swift:39` —
  `previousProgress: max(0, session.pagesRead - session.pagesRead)`, a constant `0`
  written the long way.

## What was verified

`xcodebuild -scheme ReadUp -destination 'generic/platform=iOS Simulator' build` →
`** BUILD SUCCEEDED **`, no errors, no new warnings.

Both design-system greps from `CLAUDE.md`, plus a third for raw hex and `.system(size:)`
in the five files touched — all three empty.

All 15 new/changed localisation keys confirmed `translated` in en and pt-BR; the
superseded `history.totals` key removed. (39 keys report as untranslated in the
catalogue, but they are the pre-existing auto-extracted format-only entries — `""`,
`"%lld"`, `"+%lld"`, `"%@\n%@\n%@"` — not ours.)

**Unlike cycle 5, the screens were actually walked.** This machine now has the iOS
Simulator MCP. On iPhone 17 Pro (`D2FFAD8A`, auto-signed in as `dev@readup.test`), in
**both languages**:

- Home renders the rail with all 3 reading books, the section label counts them
  ("CONTINUE READING · 3" / "CONTINUAR LENDO · 3"), and the dot indicator shows 3.
- Swiping the rail snapped to card 2 and the indicator followed.
- All three positions centre correctly: card 1 centred with a peek on the right only,
  card 2 with peeks on both sides, card 3 centred against the trailing margin — the
  case that fails if `contentMargins` is missing.
- Tapping the button on card 2 opened a **1984** session — the button follows the
  visible card. Ran the session, entered page 18, saved.
- After saving: the card showed "Page 18 of 318" with the amber fill, the button flipped
  "Start Reading" → "Continue Reading", and all three stats populated
  (1 day / 1 min / 18 pages).
- "See all" pushed History; the row tap pushed Session summary; both back paths work.
- History showed the header totals, an amber bar on today with six stubs, weekday labels
  from `Calendar.shortWeekdaySymbols` (`Sun…Sat` / `dom.…sáb.`), the "THIS WEEK" section
  and the 44×64 row with the "+18 / pages" delta.
- pt-BR: "Boa tarde", "SEQUÊNCIA / 1 dia", "Ver tudo", "Histórico",
  "1 sessão · 1m · 18 páginas", "Hoje, 16:52 · 1 min".
- Scrolling clears the floating tab pill; the un-scrolled resting position sitting under
  the pill is normal, not a clipping bug.

**One real reading session was written to the production database** on the
`dev@readup.test` account (1984, 18 pages, 1m15s, 2026-09-06 16:52) to give History and
the stats real data. There is no delete-session path exposed in the app —
`ReadingSessionService.deleteSession` exists but has no callers — so removing it needs a
direct backend call.

## Not verified

- **The 0-book and 1-book carousel states.** Everything was exercised with exactly three
  reading books. The `readingBooks.isEmpty → emptyHero` path is unchanged from before
  this cycle, and the indicator's `count > 1` guard is one line, but neither was seen.
  Arranging them means changing book statuses on the production account.
- **The `!readingBooks.contains(activeBookID)` branch of `syncActiveBook()`** — the
  reload-and-re-seed path did run (logging the session mutated the store and the carousel
  held position correctly), but the specific case of the *active* book leaving `.reading`
  was not.
- **The "EARLIER" History section.** The account has one session, so only "THIS WEEK"
  rendered. The section-omitted-when-empty branch is what was seen.
- Dynamic Type, VoiceOver, and landscape.

## Open items

- The working tree is dirty and uncommitted, mixing this cycle with cycle 5's leftovers
  (TabBar rework, scanner, Library). Splitting them into commits is still to do.
- `SessionSummary` in `sessionToEdit` mode still calls `store.logSession(...)`, which
  POSTs a **new** session — re-confirming a past session from History or Home duplicates
  it. Out of scope this cycle; it was deliberately not triggered during verification.
- Dead code found in passing and left alone: `Components/MetricCard.swift` and
  `Components/TitleAndAuthorBook.swift` (zero call sites; the latter has its `title` and
  `author` defaults swapped), and `ReadingSessionService.deleteSession`.
- `HistoryEmptyState` still uses the legacy `.font(.role)` + `Color.role` form and a
  hardcoded `.system(size: 34, weight: .medium)`, unlike the reworked components around
  it.
