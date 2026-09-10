# Session lifecycle and offline write

**Status:** approved 2026-09-09.

## Problem

A reading session was written to the backend when the user tapped **Confirm** on
`SessionSummary` — the *last* screen of the flow, not the moment the user actually
finished reading. Everything upstream of that tap treated the session as already
real:

- The Live Activity card stayed alive until the summary's Confirm, even though the
  reading itself had ended at the page-confirm alert on `ReadingSession`.
- Leaving `SessionSummary` any other way than Confirm — swipe back, backgrounding,
  a crash — never wrote the session at all. `SessionSummary` grew a rescue net for
  this: `onDisappear` called `SessionSummaryViewModel.saveSession` as a "did they
  really mean to leave without saving" fallback, guarded by a `hasSaved` flag so the
  net and the Confirm button didn't double-post.

The rescue net was a symptom, not a fix — it existed because the write was in the
wrong place. It also could not cover every exit (a force-quit doesn't run
`onDisappear` either), and its idempotency guard silently swallowed a save that a
network failure hadn't actually recorded, so the user had no way to know a session
was lost.

Two more problems rode on the same architecture:

1. **The Live Activity leaked.** Tapping the already-selected Home tab reset
   `homePath` and orphaned the view holding the activity's handle;
   `endLiveActivity()` returned early while `stageCover()`'s async cover fetch was
   still in flight, so the `Activity.request` that followed created a card nobody
   held a reference to; and a crash or force-quit left a card alive until its 8-hour
   `staleDate`, because nothing ends a stale activity on its own.
2. **A failed POST (typically no network) had exactly one outcome: the session was
   gone.** `logSession` returned `Bool`. On `false`, `SessionSummary` had already
   shown the user their finished session — there was no path back to "try again,"
   and no record survived to retry automatically.

## Decision

**Move the write to the moment the user confirms the page they stopped on**, in
`ReadingSession`'s page-confirm alert, not the summary's Confirm button. This is the
single change the rest of this cycle's session-lifecycle work hangs off:

- The session exists in `LibraryStore.sessions` (or the pending queue, see below)
  the instant page-confirm succeeds, so nothing downstream — leaving the summary
  early, closing the app, a crash — can lose it. `SessionSummary` no longer needs an
  `onDisappear` rescue net; it was deleted along with
  `SessionSummaryViewModel.saveSession`.
- The Live Activity can end at the same moment, because the thing it exists to
  represent (an in-progress session) is over. `ReadingSession`'s `onDisappear` still
  calls `endLiveActivity()` as a backstop for any other exit path, but it is now a
  backstop, not the primary path — `viewModel.savedSession == nil` is the guard, so
  it doesn't double-end after the page-confirm path already did.
- `SessionSummary` becomes a **review/share** screen for a session that is already
  saved, with two explicit modes (`.finished` / `.reviewing`) instead of inferring
  the mode from whether a `sessionToEdit` was passed in. See "Summary screen modes"
  below.
- An Instagram publish can safely pop all the way back to Home, because the session
  it was sharing already exists — reopening it from recent activity still works even
  though the summary screen itself is gone. See "Post-publish navigation" below.

### Live Activity: stop trusting the handle

Root-cause fix in `ReadingSessionViewModel.endLiveActivity()`: instead of ending
`self.activity` (a handle scoped to one view model instance), it ends *every*
`Activity<ReadingSessionAttributes>.activities` — the type-level list Apple's
ActivityKit maintains regardless of which object requested which activity. This
closes all three leaks at once:

- The handle being view-scoped no longer matters, because nothing reads the handle
  to decide what to end.
- A new `isEnded` flag is checked after the async `stageCover()` call, so leaving
  mid-request no longer lets an in-flight `Activity.request` create a card after
  `endLiveActivity()` already ran.
- `ReadUpApp.init()` sweeps `Activity<ReadingSessionAttributes>.activities` once at
  launch (`ReadingSessionViewModel.endAllReadingActivities()`), so a card orphaned
  by a crash or force-quit is gone by the time the user reopens the app, instead of
  surviving to its 8-hour `staleDate`.

### Offline write: a send-queue, not a mirror

**Considered:** block the user on a failed save — keep them on `ReadingSession` (or
show a blocking error) until the POST succeeds. **Rejected by the product owner**:
the whole point of ending the session at page-confirm is that the user is done
reading and about to lock the phone or walk away; forcing them to stay online to
finish that action defeats it, and reading happens in plenty of places without
reliable signal (transit, elevators, basements).

**Decision:** `PendingSessionStore`, a `UserDefaults`-backed JSON outbox. On a
`logSession` POST failure, the session is enqueued as a `PendingSession` snapshot,
the book's progress is applied to the in-memory `LibraryStore` immediately (so the
UI reflects the read pages right away), and a `LiterarySession` with a
`"pending:<uuid>"` id is returned so the caller's flow (navigate to summary, end the
Live Activity, show the share sheet) proceeds exactly as if the POST had succeeded.
Nothing in `ReadingSession` or `SessionSummary` needs to know a session is pending —
`LibraryStore.updateSession` is the one place that branches on the `pending:`
prefix, routing thoughts edits to the local queue instead of a network call.

Replay is triggered by `NWPathMonitor` (Apple's `Network` framework, no new
dependency) on the transition to `.satisfied`, plus once at `LibraryStore.init()` —
covering both "came back online while the app was open" and "launched with a queue
already sitting there from last time."

**Why `UserDefaults` and not SwiftData (or Core Data, or a file):** the queue holds
a handful of small `Codable` structs that live for, at most, until the next network
change — this is not app data, it's a retry buffer. `UserDefaults` already has the
project's terser precedent (`KeychainHelper` for tokens, `@AppStorage` for flags),
needs no schema, model container, or migration story, and disappears with the app if
something goes wrong rather than leaving stale rows behind. SwiftData would work,
but it would be a persistence framework brought in for a queue that never has more
than a few entries and is drained the moment there's a network.

**Cost, stated plainly:** this puts a local store back into an app whose own
`CLAUDE.md` said, accurately at the time, that there was none —
`ReadUp/CLAUDE.md` is updated as part of this cycle's docs to reflect that there is
now exactly one local store, and it is a send-queue for unsent sessions, not a
mirror of server state. Nothing else reads from local storage; the app is still
online-only for every read.

**Two correctness details, because both were bugs caught in review and neither is
obvious from the happy path:**

- **An entry leaves the queue as soon as the session POST succeeds, before the
  book-progress PUT.** The alternative — waiting for both calls to succeed before
  dequeuing — sounds safer but isn't: if the PUT fails after a successful POST, the
  entry would still be queued, and the next `flush()` would POST the same reading a
  second time. A stale book-progress value self-corrects the next time the book
  loads from the backend; a duplicated reading session does not self-correct at all.
  So the ordering is: POST → dequeue → PUT, accepting that a PUT failure leaves
  local progress briefly ahead of the server's, which the next successful load
  reconciles.
- **The `pending:` id is swapped for the real one immediately after the POST, not
  after the PUT.** If the swap waited for the PUT, a PUT failure would leave the UI
  holding a `pending:` id with no corresponding entry left in the queue (it was
  already dequeued per the point above) — an edit to that session's thoughts would
  then have nowhere to go, neither the network (id looks local) nor the queue (no
  entry).

### Summary screen modes

`SessionSummaryViewModel.Mode` (`.finished` / `.reviewing`) replaces inferring the
screen's mode from `sessionToEdit != nil`. The two no longer coincide now that a
session always exists by the time `SessionSummary` appears — reviewing an old
session and having just finished one are both "a session, already saved," so the
mode has to be passed explicitly by the caller (`ReadingSession` passes `.finished`;
`Home` and `History` pass `.reviewing`).

- **`.finished`** — "Back to home" (was "Confirm") plus "Share"; thoughts are
  editable immediately, no explicit Edit step.
- **`.reviewing`** — "Edit" (becoming "Save Changes" once tapped) plus "Share";
  thoughts are read-only until Edit is tapped.

The `sessionSummary.saveSession` string ("Confirm") is deleted along with the code
path it labeled.

### Post-publish navigation

**Considered:** leave publish behavior as-is (return to the summary, same as
closing the flow with X or falling back to the native share sheet). **Rejected**
because a freshly finished session has nowhere useful to go from the summary except
Home, and making the user tap "Back to home" *again* after they already committed
to sharing is a redundant step for the common case.

**Decision:** a new `storyFlowDidPublish` environment entry, parallel to the
existing `dismissStoryFlow`. `StoryDestinations` fires it only on the
Instagram-success branch (`StoryDestination.instagramStories` returning `true`) —
not on the native share sheet fallback, and not on closing the flow with X.
`ShareFlowView` forwards it through a new `onPublished` parameter; `SessionSummary`
uses it to call `onFinish` (which nils `activeReadingBook` and unwinds both screens
through `Home`'s `navigationDestination`) only when the flow both published *and*
the screen is in `.finished` mode. Reviewing an old session and publishing still
returns to the summary — unchanged, because there's no "back to home" implied when
the user came from Home or History in the first place.

This is only safe because of the write-at-page-confirm change above: the session
being shared already exists on the backend (or in the pending queue), so popping
away from the summary loses nothing — the user can always reopen the session from
recent activity if they want to add thoughts or check it again.

## Disabled-state contrast

Unrelated to the session-lifecycle work above but shipped in the same cycle: every
disabled control in the design system was using `Motion.disabledOpacity` (0.38) as a
group opacity over its normal colors. On `ReadUpButton`'s primary variant this
composited the ink pill (`#171512`) down to roughly `#A09B92` under its cream label
— measured at **1.7:1**, well under WCAG AA's 4.5:1 floor for body text.

**Fix:** explicit disabled tokens instead of a dimmed group. `Palette.surfaceDisabled`
(`#E4DDD0`, the same value as the existing `surface/sunken` role — a disabled button
reads as a recessed surface, not a faded one) and `Palette.inkDisabled` (`#5F584E`,
the same value as `ink/strong-muted`). Measured **5.2:1** on the disabled primary
fill and **6.3:1** on `surface`. `ReadUpButton.Variant`'s `foreground`/`background`/
`borderColor` became functions taking `isEnabled` instead of stored properties, and
`ChromeChip` gained the same `isEnabled` parameter and token swap. The one duplicate
implementation, `AuthPrimaryButton` (which dimmed itself with `Color.inkMuted`
un-measured), was deleted; its two call sites moved to `ReadUpButton`.
`ReadingSession`'s hand-rolled Finish button and `Profile.swift`'s
`Menu`-wrapped `ReadUpButtonLabel` (which previously didn't dim at all) both moved
onto the same tokens.

## Rejected alternatives (session lifecycle)

- **Keep the write on the summary's Confirm, just end the Live Activity earlier.**
  Considered as the smaller diff — it fixes the Live Activity leak without touching
  where the session is written. Rejected because it leaves the actual data-loss bug
  in place: a session could still vanish on any exit from the summary that wasn't
  Confirm, which is the bug that motivated this work in the first place. Ending the
  activity earlier is a side effect of writing the session earlier, not a
  substitute for it.
- **Retry a failed save inline on `ReadingSession`, no queue.** Rejected because it
  reintroduces the blocking-the-user problem the product owner already ruled out,
  and it doesn't survive the app being closed before the retry succeeds.
