# Cycle 8 — Post-launch fixes

Implements [`specs/2026-09-09-session-lifecycle-and-offline-write.md`](../specs/2026-09-09-session-lifecycle-and-offline-write.md),
following [`plans/2026-09-09-cycle-8-post-launch-fixes.md`](../plans/2026-09-09-cycle-8-post-launch-fixes.md).

Both repositories are uncommitted at the time of writing — no commit SHA to
reference for either.

## Files

### iOS (`ReadUp`)

| File | What |
|---|---|
| `ReadUp/Views/ReadingSession.swift` | Page-confirm alert now writes the session (`store.logSession`) and navigates to `SessionSummary` with the result; Finish button moved to `ReadUpButton`; a save failure shows an alert (reused title/message state) without navigating or ending the Live Activity. |
| `ReadUp/ViewModels/ReadingSessionViewModel.swift` | `isShowingSummary` → `savedSession: LiterarySession?`; `endLiveActivity()` rewritten to sweep `Activity<ReadingSessionAttributes>.activities` instead of trusting `self.activity`; new `isEnded` flag; new static `endAllReadingActivities()`. |
| `ReadUp/App/ReadUpApp.swift` | Calls `ReadingSessionViewModel.endAllReadingActivities()` once at launch. |
| `ReadUp/Views/SessionSummary.swift` | `onDisappear` rescue net removed; buttons and back-button-hidden state driven by `viewModel.mode`; `didPublish` tracks Instagram success for post-publish navigation. |
| `ReadUp/ViewModels/SessionSummaryViewModel.swift` | New `Mode` enum (`.finished`/`.reviewing`); `init` takes `session:`/`mode:`; `saveSession()` deleted; new `finish(store:)`. |
| `ReadUp/Services/PendingSessionStore.swift` | New. `UserDefaults`-backed JSON outbox for sessions that failed to POST. |
| `ReadUp/ViewModels/LibraryStore.swift` | `logSession` returns `LiterarySession?`; enqueues + applies local progress on failure; `NWPathMonitor` triggers `flush` on `.satisfied` and once at init; `updateSession` routes `pending:` ids to the local queue. |
| `ReadUp/Models/LiterarySession.swift` | `id` is now `var` (swapped after a queued session replays successfully). |
| `ReadUp/Services/ReadingSessionService.swift` | `CreateSessionPayload` gains optional `date`. |
| `ReadUp/Views/Share/StoryShare.swift`, `ShareFlowView.swift` | New `storyFlowDidPublish` environment entry, fired only on the Instagram-success branch; forwarded through `ShareFlowView.onPublished`. |
| `ReadUp/Views/Home.swift`, `History.swift` | Updated call sites: `session:`/`mode: .reviewing` instead of `sessionToEdit:`. |
| `ReadUp/DesignSystem/Theme+Color.swift` | `Palette.surfaceDisabled` (`#E4DDD0`, = `surfaceSunken`), `Palette.inkDisabled` (`#5F584E`, = `inkStrongMuted`), exposed on `Color` and `ShapeStyle`. |
| `ReadUp/DesignSystem/Theme+Surfaces.swift` | `ReadUpButton.Variant.foreground/background/borderColor` become `isEnabled`-taking functions; group-opacity dimming removed from `ReadUpButton` (kept only for text-only press-dim); `ChromeChip` gains `isEnabled`; `TextField("", …)`/`SecureField("", …)` calls forced to the non-localized overload via `"" as String`. |
| `ReadUp/Views/Auth/AuthComponents.swift` | `AuthPrimaryButton` deleted. |
| `ReadUp/Views/Auth/ForgotPasswordView.swift`, `ResetPasswordView.swift` | Moved to `ReadUpButton`. |
| `ReadUp/Views/Profile.swift` | `Menu`-wrapped `ReadUpButtonLabel` now takes `isEnabled: !authManager.isLoading`. |
| `ReadUp/Views/BookFormView.swift`, `Views/Scanner/ScannedBookSheet.swift` | `ChromeChip` call sites moved from manual `.opacity(Motion.disabledOpacity)` + `.disabled` to `isEnabled:`. |
| `ReadUp/Views/Search.swift` | Add-to-library circle moved off `.opacity(Motion.disabledOpacity)` to explicit `Palette.surfaceDisabled`/`inkDisabled`. |
| `ReadUp/Views/Library.swift` | New `notFoundState` for a non-empty query matching nothing in the library; wired to the existing add-options chooser. |
| `ReadUp/Localizations/Localization+Library.swift`, `Localization+ReadingSession.swift`, `Localization+SessionSummary.swift` | New/removed keys matching the above. |
| `ReadUp/Localizable.xcstrings`, `ReadUpWidgets/Localizable.xcstrings` | See "String catalog" below. |
| `ReadUp.xcodeproj/project.pbxproj` | `"pt-BR"` added to `knownRegions`. |
| `ReadUp/Components/GridCover.swift`, `RecentActivityRow.swift`, `Onboarding/OnboardingTour.swift`, `Onboarding/WelcomeView.swift`, `Views/Share/StoryEditorView.swift` | Display-literal `Text("…")` call sites converted to `Text(verbatim:)`. |

### Backend (`ReadUpBackend`)

| File | What |
|---|---|
| `src/dtos/reading-session.dto.ts` | `CreateReadingSessionDTO.date?: string`. |
| `src/repositories/reading-session.repository.ts` | Uses `data.date` when present, otherwise leaves Prisma's `@default(now())`. |
| `src/services/reading-session.service.ts` | New exported `validateCreateSessionInput`, called at the top of `createSession`. |
| `src/services/reading-session.service.test.ts` | New. 9 cases: valid input with/without `date`, missing/negative/non-integer `pagesRead` and `readingTimeSeconds`, invalid `date`, future `date`. |

## Decisions made during implementation the plan didn't already cover

**Queue-dequeue ordering (POST-then-dequeue-then-PUT, id swap right after POST).**
Covered in depth in the spec; recorded here because it was a bug caught in review,
not designed up front. Dequeuing only after both the session POST and the book PUT
succeeded looked safer on first pass but double-posts the reading on a PUT failure,
since the next `flush()` would replay an entry that was never removed. Progress
being briefly stale self-heals on the next book load; a duplicated session does not.
The id swap has the same shape of bug: swapping it after the PUT instead of right
after the POST would leave a `pending:` id on screen with no queue entry behind it
if the PUT failed, orphaning any thoughts edit made in that window.

**The "add this book" empty state deliberately doesn't cover the status-filter
case.** `Library.notFoundState` only shows when the search query is non-empty *and*
`filteredBooks.isEmpty` — i.e., the book really isn't anywhere in the library. If
the query matches a book that exists but is hidden by the active status filter (say,
searching for a book that's marked "abandoned" while the filter shows only
"reading"), the generic `noResultsState` still applies, because the book *is* in the
library and "Add this book" would be the wrong action — it's already added.

**`Motion.disabledOpacity` is not dead code.** One caller remains:
`ReadUp/Views/Scanner/ISBNScanView.swift:209` dims an already-added row in the batch
scan list (`book.isAdded ? Motion.disabledOpacity : 1`), which is a "this item is
done" affordance on a list row, not a disabled *control* — it wasn't touched, and
`Theme+Layout.swift`'s definition stays.

## What was verified and how

**Backend.** `npm test` (`tsc && node --test`) — 53 tests pass, 0 fail, including
the new 9-case `reading-session.service.test.ts`. Confirmed the validation errors
surface as HTTP 400 by reading `ReadingSessionController.create`'s catch block: it
maps `'Book not found'` → 404, `'Access denied'` → 403, and everything else
(including every `validateCreateSessionInput` throw) → 400.

**String catalog.** Diffed `Localizable.xcstrings` key-by-key against the pre-cycle
version: 29 keys removed (7 display-literal auto-extractions, 18 dead `ai.*` keys,
3 untranslated format/accessibility leftovers, `sessionSummary.saveSession`), 6 keys
added (the new `library.notFound*`, `readingSession.saveFailed*`,
`sessionSummary.backToHome`). Net: **320 → 297 keys**, not the 320 → 292 figure
floated before this doc was written — see Discrepancies below.

**AI assistant removal.** `grep -rl "AIChatView\|LiteraryAssistantViewModel\|LiteraryTopicClassifier"`
across `ReadUp/` and `ReadUpWidgets/` returns nothing — confirmed gone from the iOS
tree, matching the backend's earlier `fe21707` removal commit.

**Live Activity / session-write flow.** Read end-to-end, not device-tested in this
pass: `ReadingSession`'s page-confirm alert → `store.logSession` → on success,
`endLiveActivity()` then `savedSession` set → `navigationDestination(item:)` fires.
The `guard let session else` branch (only reachable with no auth token — an offline
POST failure returns a `pending:` session, not `nil`) was traced but not
exercised on a signed-out device.

## What was deliberately left out

- No device verification of the offline queue's actual airplane-mode → reconnect
  path in this pass — the code was read and traced (see spec for the two
  correctness fixes that *were* caught this way), but this handoff does not claim a
  physical on-device replay was run.
- No new test coverage on the iOS side — the project still has no XCTest target,
  consistent with every prior cycle's handoff.

## Discrepancies found against the reported description

These are corrections to claims made about this cycle before this handoff was
written, found by reading the actual diff and running the actual build/test tools —
per this project's "trust the tree" convention.

1. **String catalog count is wrong.** The description claimed "Catalog went 320 →
   292 keys." The actual, verified count (key-by-key diff of `Localizable.xcstrings`
   against the pre-cycle version) is **320 → 297**: 29 removed, 6 added. The
   category breakdown given (7 display-literal keys, 3 untranslated leftovers, 18
   dead `ai.*` keys, plus the 6 new keys this cycle needed) is otherwise accurate
   and sums correctly to the real 297.
2. **`project.pbxproj` also changed `CURRENT_PROJECT_VERSION` (2 → 1) and
   `MARKETING_VERSION` (1.5 → 2.1)**, in both the Debug and Release configurations.
   Neither change is mentioned anywhere in the reported work, and the project
   version *decreasing* (2 → 1) alongside a marketing version *increasing* (1.5 →
   2.1) looks unintentional — worth confirming with whoever edited the project
   settings before this lands, since Xcode/App Store Connect treats a decreasing
   build number as a regression. Left as found; this is documentation only.

Everything else in the reported description — the page-confirm write move, the
three Live Activity leak causes and their fixes, the offline queue's two
correctness details, the summary screen's two modes, the post-publish navigation,
the disabled-button contrast ratios and token names, the library search empty
state, and the backend `date`/validation change — matches the diff as written.

---

## Follow-up: three defects found in device testing, after the cycle

The user recorded a real run on device. Three things the static verification could
not have caught, all fixed in the same working tree.

### 1. Publishing to Instagram never left the story editor

The post-publish navigation this cycle added did not work — and neither did the
`dismissStoryFlow` it was modelled on, which had been shipped broken since cycle 7.

**Root cause:** `ShareFlowView` applied `.environment(\.dismissStoryFlow)` (and the
new `.environment(\.storyFlowDidPublish)`) to the `VStack` *inside* its
`NavigationStack`. A destination registered with `navigationDestination` is
instantiated by the stack itself, not as a child of the view carrying the modifier,
so neither value ever reached `StoryEditorView` / `StoryReadyView`. `StoryDestinations`
was reading the default empty closure: the Instagram branch called `{}` twice and
nothing happened. Screen recording confirms the app returns from Instagram to the
editor, exactly as before the change.

**Fix:** the environment channel was removed entirely — both `@Entry` values are
gone — and replaced with an explicit `onPublished: () -> Void` threaded
`ShareFlowView` → `StoryEditorView`/`StoryReadyView` → `StoryDestinations`.
`ShareFlowView.publish()` calls the caller's closure and then `dismiss()`.
Moving the modifiers outside the `NavigationStack` would probably also have worked,
but "probably" was not good enough for a fix that had already failed once in the
user's hands; a plain closure parameter has no propagation semantics to get wrong.
The X-close and native-share-sheet paths are untouched and still return to the summary.

### 2. The share card rendered the typographic placeholder instead of the cover

`SessionSummary` fetched the cover for the share card with
`GoogleBooksService().loadImageData(...)` — a fresh `URLSession` download, separate
from `CoverImageCache`, which already held the decoded image because the summary's
own book card had just drawn it. When that second download was slow or failed, the
card fell back to the placeholder while the real cover sat in memory two views up.

**Fix:** the `.task` now uses `CoverImageCache.load(url)` (the same cache
`ReadingSessionViewModel.stageCover` already uses for the Live Activity), and `story`
falls back to the synchronous `CoverImageCache.image(for:)` so that tapping Share
before the task resolves still gets the cover. `GoogleBooksService.loadImageData` had
no callers left and was deleted.

### 3. The tab-bar pill rode up above the keyboard

Typing in Library's search field lifted the custom pill and parked it in the middle of
the book grid. The pill is a `ZStack` child, so SwiftUI's keyboard safe-area inset
moved it like any other content.

**Fix:** `.ignoresSafeArea(.keyboard, edges: .bottom)` on `pillContent` in
`TabBar.swift`. The keyboard now covers the pill, which is what chrome anchored to the
bottom of the screen should do; the grid's own keyboard avoidance is unchanged.

### Verification status of the follow-up

`xcodebuild` succeeds with zero warnings, and the app launches. **None of the three
was verified at runtime**: the build on this machine lands in guest mode (the
`DEV_*` auto-login did not take), which puts Library's search field behind the
sign-in wall, and the Instagram hand-off cannot be exercised in the Simulator at all
(`canOpenURL` fails with the app absent, so the code takes the share-sheet branch).
These need a device pass.

### 4. Historical sessions showed the session's delta as the book's total progress

Reported as "progress is not cumulative". The live path was already correct (a recorded
run shows `32 / 360`, 9%, after a 1-page session on a book at page 31). The bug was in
**review mode**: `Home.swift` and `History.swift` opened `SessionSummary` with
`pagesRead: session.pagesRead, previousProgress: 0`. But `ReadingSession.pagesRead` is
the *delta* — pages read in that session — so a 10-page session and then an 11-page
session rendered as `10/300` and `11/300`, each session's own delta drawn as if it were
the book's total, progress bar included.

**Fix:** `LibraryStore.cumulativeProgress(upTo:)` sums the deltas of earlier sessions of
the same book and returns `(previous, total)`; both call sites pass those instead of
`(0, delta)`. The two now read `10/300` and `21/300`, and `sessionPagesRead`
(`total - previous`) still yields the per-session count for the Pages stat.

Marked with a `ponytail:` comment: this diverges if book progress is edited by hand in
the book form, since the sum only knows about sessions. Storing the resulting progress
on the session row would be exact, but needs a new column and a migration against the
production Supabase database — deliberately not done here.

### 5. Tab-bar pill still rode the keyboard

The first attempt put `.ignoresSafeArea(.keyboard, edges: .bottom)` on `pillContent`,
which did nothing: the pill is anchored to the `.bottom` of the per-tab `ZStack`, and it
is the **ZStack** the keyboard inset shrinks. Opting the pill out of the inset just left
it following the stack's new, higher bottom edge. The modifier moved to the three
ZStacks themselves.

Safe here because no tab has a bottom-anchored text field that needs the view to shift:
Library's search field is at the top, Home has no text input, and Profile's only field
lives inside an `.alert`, which positions itself independently of the host's safe area.

Library also gained tap-outside-to-dismiss — `.simultaneousGesture(TapGesture())` +
`hideKeyboard()`, the same pair `SessionSummary` already used — plus
`.scrollDismissesKeyboard(.interactively)`.

**Still unverified at runtime.** A fresh install lands on the welcome screen rather than
auto-logging in, so Library stays behind the sign-in wall in this environment; verifying
either fix needs signing in, which was not done.

### 6. `setupForEditting` undid the cumulative-progress fix

Fix 4 was only half-applied. `SessionSummaryViewModel.setupForEditting()`, which runs
`.onAppear` in review mode, re-read `pagesRead = session.pagesRead` — overwriting the
cumulative total the caller had just computed with the session's own delta.

The recorded evidence: a Murdle session of +15 pages, on a book whose earlier session was
+9, rendered `15 / 384` with a "Pages" stat of **6**. That is the signature of the
clobber — `previousProgress` survived as 9 (so Pages showed `15 - 9 = 6`), while
`pagesRead` was reset from the correct 24 down to the delta 15. Neither the pre-fix nor
the post-fix behaviour alone produces those two numbers together; only the mix does.

**Fix:** `setupForEditting` no longer touches `pagesRead`; the caller owns it. The same
session now reads `24 / 384`, Pages 15, 6%.

Lesson worth keeping: the screen had two sources for one value — an injected one and a
re-read one — and they disagreed only in review mode, which is why the live path looked
correct throughout.

### 7. Home carousel ordered by shelf order, not by reading recency

`readingBooks` was `books.filter { $0.status == .reading }`, inheriting the backend's
creation order, so the book read yesterday could sit behind one untouched for a month —
and since `syncActiveBook` centres `readingBooks.first`, the carousel opened on an
arbitrary book.

**Fix:** sorted by each book's most recent session date, descending, with books that have
no session at all falling to the end alphabetically. `Dictionary(_:uniquingKeysWith: max)`
over `store.sessions` gives the last-read date per book in one pass.

### Note: the three-line reading card was already fixed in the working tree

`CurrentlyReadingCard` built its second line as `"\(book.author) · " + pageOf(...)` under
`lineLimit(1)`, so on the 232pt carousel card any moderately long author name ate the
page count. The working tree already carries the fix — title, author and page count as
three separate `Text` lines in their own `VStack` — made outside this session. Recorded
here only so the cycle's history is complete; nothing was changed for it.
