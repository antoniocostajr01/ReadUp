# Cycle 8 — Post-launch fixes implementation plan

**Goal:** A grab-bag of fixes reported after cycle 7 shipped, unified by one
architectural change: move the reading session write from the summary screen's
Confirm to the page-confirm alert on `ReadingSession`, which is what makes the Live
Activity leak, the summary's two modes, and safe post-publish navigation all
fixable at their root instead of patched individually. Plus an offline write queue,
a legibility fix for disabled controls, a library search dead end, and a string
catalog cleanup.

**Architecture:** No new screens. `ReadingSession` gains the responsibility of
writing the session (`LibraryStore.logSession`) and pushing `SessionSummary` with
the result; `SessionSummary` stops being able to *cause* a save and becomes a
review/share surface with an explicit `Mode`. `PendingSessionStore` is a new,
narrowly-scoped `UserDefaults` outbox — not a general offline layer. Backend gets an
optional `date` on session creation (for replay) and its first real input
validation on that endpoint.

**Tech Stack:** SwiftUI/`@Observable`, Apple's `Network` framework (`NWPathMonitor`,
already available, no new dependency) for connectivity detection. Backend: no new
dependencies; `validateCreateSessionInput` is plain TypeScript, tested with node's
built-in test runner.

**Spec:** [`.claude/specs/2026-09-09-session-lifecycle-and-offline-write.md`](../specs/2026-09-09-session-lifecycle-and-offline-write.md)

## Global Constraints

- Repositories: `/Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp` (iOS) and
  `/Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend` (Express/Prisma).
  Both trees are uncommitted as this plan is written — no branch/base SHA to record.
- Code comments: Portuguese. `.md` files: English.
- No blocking UX on a failed session save — see spec's rejected-alternatives section.
  A failed POST always degrades to "queued locally," never to "tell the user to try
  again before they can leave."
- Backend `DATABASE_URL` points at production Supabase — no schema change needed
  this cycle (`date` already exists on `ReadingSession` with `@default(now())`), so
  no `prisma migrate` step applies.
- No XCTest target in the iOS project; verification is `xcodebuild` plus targeted
  runtime checks, same as prior cycles.

## File Structure

| File | Change |
|---|---|
| `ReadUp/Views/ReadingSession.swift` | page-confirm alert now calls `store.logSession` and navigates on the result |
| `ReadUp/ViewModels/ReadingSessionViewModel.swift` | `isShowingSummary` replaced by `savedSession`; `endLiveActivity()` rewritten to sweep all activities; new `isEnded` guard |
| `ReadUp/App/ReadUpApp.swift` | launch-time sweep via `ReadingSessionViewModel.endAllReadingActivities()` |
| `ReadUp/Views/SessionSummary.swift` | `onDisappear` rescue net deleted; `Mode`-driven buttons; `onPublished` wired to `onFinish` |
| `ReadUp/ViewModels/SessionSummaryViewModel.swift` | `Mode` enum added; `saveSession()` deleted; new `finish(store:)` |
| `ReadUp/Services/PendingSessionStore.swift` | new — `PendingSession`, `UserDefaults` outbox, `flush(store:)` |
| `ReadUp/ViewModels/LibraryStore.swift` | `logSession` returns `LiterarySession?` instead of `Bool`; enqueues on failure; `NWPathMonitor` wired in `init()`; `updateSession` routes `pending:` ids locally |
| `ReadUp/Models/LiterarySession.swift` | `id` becomes `var` (swapped after successful replay) |
| `ReadUp/Services/ReadingSessionService.swift` | `CreateSessionPayload` gains optional `date` |
| `ReadUp/Views/Share/StoryShare.swift`, `ShareFlowView.swift` | new `storyFlowDidPublish` environment entry, wired through `onPublished` |
| `ReadUp/Views/Home.swift`, `History.swift` | pass `session:`/`mode: .reviewing` instead of `sessionToEdit:` |
| `ReadUp/DesignSystem/Theme+Color.swift` | `Palette.surfaceDisabled`, `Palette.inkDisabled` |
| `ReadUp/DesignSystem/Theme+Surfaces.swift` | `ReadUpButton.Variant` methods take `isEnabled`; `ChromeChip` gains `isEnabled` |
| `ReadUp/Views/Auth/AuthComponents.swift` | `AuthPrimaryButton` deleted |
| `ReadUp/Views/Auth/ForgotPasswordView.swift`, `ResetPasswordView.swift` | moved to `ReadUpButton` |
| `ReadUp/Views/Profile.swift`, `Views/BookFormView.swift`, `Views/Scanner/ScannedBookSheet.swift`, `Views/Search.swift` | disabled-state token adoption |
| `ReadUp/Views/Library.swift` | `notFoundState` for a query matching nothing |
| `ReadUp/Localizations/Localization+*.swift`, `Localizable.xcstrings` | new/removed keys; junk-key cleanup; `Text(verbatim:)` conversions |
| `ReadUp.xcodeproj/project.pbxproj` | `pt-BR` added to `knownRegions` |
| `ReadUpBackend/src/dtos/reading-session.dto.ts` | optional `date` on `CreateReadingSessionDTO` |
| `ReadUpBackend/src/repositories/reading-session.repository.ts` | uses `data.date` when present |
| `ReadUpBackend/src/services/reading-session.service.ts` | new `validateCreateSessionInput`, called from `createSession` |
| `ReadUpBackend/src/services/reading-session.service.test.ts` | new — validation coverage |

---

### Phase 1: Write the session at page-confirm, not summary-confirm

**Files:** `ReadUp/Views/ReadingSession.swift`, `ReadUp/ViewModels/ReadingSessionViewModel.swift`, `ReadUp/ViewModels/LibraryStore.swift`, `ReadUp/Views/SessionSummary.swift`, `ReadUp/ViewModels/SessionSummaryViewModel.swift`, `ReadUp/Views/Home.swift`, `ReadUp/Views/History.swift`

- [x] `LibraryStore.logSession` returns `LiterarySession?` instead of `Bool`.
- [x] `ReadingSessionViewModel.savedSession: LiterarySession?` replaces
      `isShowingSummary`; `ReadingSession` drives `.navigationDestination(item:)` off
      it.
- [x] Page-confirm alert's OK action calls `store.logSession(...)`, sets
      `viewModel.savedSession` on success, ends the Live Activity on success, and on
      `nil` (only reachable with no auth token) shows a `saveFailed` alert without
      navigating or ending the activity.
- [x] `SessionSummaryViewModel.Mode` (`.finished`/`.reviewing`) added; `init` takes
      `session:` (non-optional) and `mode:` instead of `sessionToEdit:`.
- [x] `saveSession()` deleted; new `finish(store:)` persists thoughts (if any) and
      returns — no toast, no blocking, per spec.
- [x] `SessionSummary`'s `onDisappear` rescue net deleted.
- [x] `Home`/`History` pass `session: session, mode: .reviewing`.

### Phase 2: Live Activity — stop leaking

**Files:** `ReadUp/ViewModels/ReadingSessionViewModel.swift`, `ReadUp/App/ReadUpApp.swift`

- [x] `endLiveActivity()` rewritten to end every
      `Activity<ReadingSessionAttributes>.activities`, not `self.activity`.
- [x] `isEnded` flag checked after `stageCover()`'s await, before the
      `Activity.request` call.
- [x] `ReadingSessionViewModel.endAllReadingActivities()` (static) added, called
      from `ReadUpApp.init()`.

### Phase 3: Offline write queue

**Files:** `ReadUp/Services/PendingSessionStore.swift` (new), `ReadUp/ViewModels/LibraryStore.swift`, `ReadUp/Models/LiterarySession.swift`, `ReadUp/Services/ReadingSessionService.swift`

- [x] `PendingSessionStore`: `PendingSession` (Codable snapshot), `enqueue`,
      `updateThoughts`, `remove`, `flush(store:)`.
- [x] `LibraryStore.logSession` catch path: enqueue, apply progress locally, return
      a `"pending:<uuid>"` session instead of `nil`.
- [x] `LibraryStore.updateSession` branches on the `pending:` prefix to route to
      `PendingSessionStore.updateThoughts` instead of the network.
- [x] `LibraryStore.init()` wires `NWPathMonitor`; flush on `.satisfied` and once at
      init.
- [x] `flush(store:)` dequeues after the session POST succeeds (before the book PUT)
      and swaps the `pending:` id for the real one at the same point — see spec for
      why both orderings matter.
- [x] `LiterarySession.id` becomes `var` to allow the swap.

### Phase 4: Post-publish navigation

**Files:** `ReadUp/Views/Share/StoryShare.swift`, `ReadUp/Views/Share/ShareFlowView.swift`, `ReadUp/Views/SessionSummary.swift`

- [x] `storyFlowDidPublish` environment entry added alongside `dismissStoryFlow`.
- [x] `StoryDestinations` fires it only on the Instagram-success branch.
- [x] `ShareFlowView` gains `onPublished` parameter, forwards to the environment.
- [x] `SessionSummary` tracks `didPublish`; on the share `fullScreenCover`'s
      `onDismiss`, calls `onFinish` only when `didPublish && mode == .finished`.

### Phase 5: Backend — replay date and input validation

**Files:** `ReadUpBackend/src/dtos/reading-session.dto.ts`, `src/repositories/reading-session.repository.ts`, `src/services/reading-session.service.ts`, `src/services/reading-session.service.test.ts`

- [x] `CreateReadingSessionDTO.date?: string` (ISO8601).
- [x] Repository uses `data.date` when present, otherwise leaves Prisma's
      `@default(now())` alone.
- [x] `validateCreateSessionInput` (pure function, no Prisma): rejects missing,
      non-integer, or negative `pagesRead`/`readingTimeSeconds`; rejects an
      unparseable or future `date`.
- [x] Called from `ReadingSessionService.createSession` before the existing
      book-ownership check.
- [x] Test file covers each rejection case plus the valid-input path, using
      node's built-in `node:test`/`node:assert` — no framework, matching the
      existing `search/` test style.

### Phase 6: Disabled-state contrast

**Files:** `ReadUp/DesignSystem/Theme+Color.swift`, `Theme+Surfaces.swift`, `ReadUp/Views/Auth/AuthComponents.swift`, `ForgotPasswordView.swift`, `ResetPasswordView.swift`, `ReadUp/Views/Profile.swift`, `ReadUp/Views/BookFormView.swift`, `ReadUp/Views/Scanner/ScannedBookSheet.swift`, `ReadUp/Views/Search.swift`, `ReadUp/Views/ReadingSession.swift`

- [x] `Palette.surfaceDisabled` (`#E4DDD0`), `Palette.inkDisabled` (`#5F584E`).
- [x] `ReadUpButton.Variant.foreground/background/borderColor` become
      `isEnabled`-taking functions; the button's own group-opacity dimming for
      disabled/loading removed (kept only for the press-dim of text-only buttons).
- [x] `ChromeChip` gains `isEnabled`, applies the same tokens.
- [x] `AuthPrimaryButton` deleted; `ForgotPasswordView`/`ResetPasswordView` moved to
      `ReadUpButton`.
- [x] `ReadingSession`'s hand-rolled Finish button replaced with `ReadUpButton`.
- [x] `Profile.swift`'s `Menu`-wrapped `ReadUpButtonLabel` gets `isEnabled:
      !authManager.isLoading` (previously didn't dim at all).
- [x] `BookFormView`/`ScannedBookSheet`/`Search` call sites that manually applied
      `Motion.disabledOpacity` over `ChromeChip` moved to `isEnabled:`.

### Phase 7: Library search dead end

**Files:** `ReadUp/Views/Library.swift`, `Localization+Library.swift`, `Localizable.xcstrings`

- [x] `notFoundState`: shown only when the query is non-empty AND
      `filteredBooks.isEmpty` (i.e. the book genuinely isn't in the library, not
      merely hidden by the status filter) — the generic `noResultsState` still
      covers the status-filter case and the empty-library case.
- [x] "Add this book" opens the existing add-options chooser (`isShowingAddOptions`).
- [x] `library.notFoundTitle`/`notFoundMessage`/`notFoundAction` added.

### Phase 8: String catalog cleanup

**Files:** `ReadUp/Localizable.xcstrings`, and every call site listed in the spec's
description that passed a display literal to `Text("…")`.

- [x] Convert display-literal `Text("…")` call sites to `Text(verbatim:)` across
      `OnboardingTour`, `StoryEditorView`, `WelcomeView`, `GridCover`,
      `RecentActivityRow`, `ReadingSession`, `SessionSummary`, `Library`; convert
      `TextField("", …)`/`SecureField("", …)`/`ColorPicker("", …)` call sites to the
      `as String` form to force the non-localized overload
      (`Theme+Surfaces.swift`, `BookFormView.swift`, `StoryEditorView.swift`).
- [x] Remove the resulting junk keys from `Localizable.xcstrings`, plus the already
      dead `ai.*` keys (feature removed pre-cycle) and untranslated format/
      accessibility leftovers.
- [x] Add the missing pt-BR translation for `search.unknown_author`.
- [x] Add `"pt-BR"` to `knownRegions` in `project.pbxproj`.
- [x] Verify a clean Xcode build emits zero string-catalog warnings.
