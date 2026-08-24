# Cycle 3 — Batch ISBN scanning + Library "+" entry point

Executed 2026-08-18. No spec file for this cycle: the design was settled interactively
(scope questions answered before planning), and the plan lived outside `.claude/plans/`.

## What shipped

**Backend (`ReadUpBackend`)** — new public `GET /books/lookup?isbn=`:

- `openlibrary.provider.ts` — `lookupIsbn(isbn)`, two requests:
  `/isbn/{isbn}.json` for the edition, then `search.json?q=key:/works/…` for the work.
  Edition title / pages / cover win over the work's; author and description come from
  the work. No `filterDocs` (popularity separates work from derivative in a *text*
  search; a barcode is already the exact book).
- `google-books.provider.ts` — `lookupIsbnFallback(isbn)`, `q=isbn:`, no `langRestrict`.
- `book-search.service.ts` — `lookupIsbn(isbn)`: normalize to digits+`X`, validate
  `/^(\d{9}[\dX]|\d{13})$/`, 7-day `TtlCache` (negatives cached too), OL → Google.
- `book.controller.ts` / `book.routes.ts` — 400 / 404 / 200; route registered above
  `authMiddleware` and `/:id`.
- 6 new tests in `book-search.service.test.ts`. Suite: 42/42.

**iOS app** — scanner and navigation:

- `Views/Scanner/ISBNScannerRepresentable.swift` — VisionKit `DataScannerViewController`,
  `.ean13/.ean8/.upce`.
- `ViewModels/ISBNScannerViewModel.swift` — dedupe by ISBN, concurrent resolve, per-book
  status, `addAll(to:)`.
- `Views/Scanner/ISBNScanView.swift` — full-screen camera + scanned list in a partial
  sheet with `presentationBackgroundInteraction(.enabled)`.
- `Services/GoogleBooksService.swift` — `lookupISBN(_:)`, 404 → `nil`.
- `ViewModels/LibraryStore.swift` — `addBook(from:status:isbn:)`; the scanned ISBN is now
  persisted (the column and `CreateBookPayload.isbn` already existed and were unused).
- `App/TabBar.swift` — Search tab renders only for guests; `App/AppTabState.swift` deleted.
- `Views/Library.swift` — `+` opens a `confirmationDialog`: Scan / Search / Add manually.
- New `scan.*` + `library.addMenu.scan` keys in `Localizable.xcstrings` (en + pt-BR),
  `INFOPLIST_KEY_NSCameraUsageDescription` in both build configs.

## Decisions made during implementation, not in the plan

**The plan's Open Library query was wrong, and a live smoke test caught it.** The plan
specified `search.json?q=isbn:X` as the resolver. That endpoint is fuzzy: for
`9789999999991` it returns three works and the top one is not the scanned book. Returning
the wrong book is the worst outcome a scanner can produce, so the resolver became
`/isbn/{isbn}.json` — the edition record, which 404s instead of guessing — with the work
query only filling in author and description. `bad checksum` (`9781111111119`) now
correctly returns null where the fuzzy query would still have answered.

**`localize` is deliberately NOT applied to ISBN lookups.** It swaps a work's title for
its Portuguese edition. The barcode already identified an exact edition, so localizing
would overwrite the right answer with a different one.

**Dropped as dead on review:** `lang` on `lookupIsbnFallback` (no `langRestrict`, so it was
unused), `lang` on `BookSearchService.lookupIsbn` and its cache key (the result does not
depend on it), `Task.detached` + `MainActor.run` + `weak self` in the scanner view model
(the class is already `@MainActor`; a plain `Task` does the same in four lines).

**Guest mode.** Removing the Search tab outright would have left guests with nothing but
sign-in walls, since Home/Library/Profile are all gated. The tab is now conditional on
`authManager.isGuest`, and `.tag` numbers were kept so the existing guest landing
(`selectedTab = 2`) still works.

## Verified

- `npm test` in `ReadUpBackend` — 42/42, `tsc` clean.
- Live lookups against Open Library through the compiled service: `9788535914849` →
  1984 / Orwell / 416p / cover / synopsis; `9780241968659` → Strange Pilgrims / García
  Márquez / 208p; malformed and bad-checksum ISBNs → null.
- `xcodebuild … -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` →
  BUILD SUCCEEDED; app installs and launches on the simulator.

## Not verified — needs a physical device

`DataScannerViewController` is unsupported in the Simulator (the screen shows its
`ContentUnavailableView` fallback there). Untested end to end: camera permission prompt,
real barcode recognition, scan dedupe while a barcode sits in frame, and the
"Add N books" write path. The Library `+` dialog itself also went unverified
interactively, since reaching Library requires signing in.

## Round 2 — accuracy and data quality (same day, after first device test)

Device testing exposed three things the local smoke test could not:

1. **Open Library alone is thin for Brazilian books.** "Entendendo Algoritmos" resolved
   with title/author/cover but 0 pages and no synopsis; "Crime e Castigo"
   (9786558881483) 404'd entirely though Google Books has it.
2. **Open Library is slow and flaky** — 6 to 11 seconds per request from a home
   connection, with intermittent ECONNRESET. Two sequential OL calls meant a valid book
   regularly surfaced as "Not found".
3. **Google's `q=isbn:` is a search, not a lookup** — for the invalid 9781111111119 it
   happily returned an unrelated book.

Changes:

- `book-search.service.ts` — the two providers now run in `Promise.all` and merge field
  by field (`mergeEditions`): Open Library wins where it has a value (it is the exact
  scanned edition), Google fills every gap. Neither source alone was sufficient.
- `google-books.provider.ts` — renamed `lookupIsbnFallback` → `lookupIsbnVolume` (it is a
  peer now, not a fallback) and added `carriesIsbn`: a volume is accepted only if its
  `industryIdentifiers` actually contain the scanned ISBN.
- `openlibrary.provider.ts` — `AbortSignal.timeout(12s)` on every OL request (this also
  protects the existing text search, which could hang the same way); the work lookup is
  now best-effort, so a slow work query degrades to edition-only data instead of losing
  the book; ISBN covers request size `L` (~450px) instead of `M`, since the detail screen
  renders the cover at roughly that size.
- Negative results are **no longer cached**. A 7-day cached `null` would have turned a
  few minutes of Open Library downtime into "this book does not exist" until redeploy.
- `console.warn` when `GOOGLE_BOOKS_API_KEY` is missing — silently losing half the
  coverage was indistinguishable from the book not existing.

Suite: 44/44. Live, repeated: all three previously-failing ISBNs resolve with covers on
every round; invalid ISBNs still return null.

## Known upstream limits

- Google reports `pageCount: 30` for Entendendo Algoritmos and `0` for Crime e Castigo.
  That is what the API returns; no heuristic was added to second-guess it — the user can
  correct pages in the edit form.
- Open Library covers are served via a 302 to archive.org, which is intermittently slow.
  `AsyncImage` does not retry, so a cover can render blank on a bad request. Proxying
  covers through the backend (like `/books/:id/cover` already does for uploads) is the
  fix if it keeps happening.

## Follow-ups

- `RootView` still preloads the Search view model's genre shelves at login, though Search
  is now a sheet most users won't open. Cheap and cached; left alone.
- `GoogleBooksService` is doubly misnamed — it proxies Open Library and now does ISBN
  lookups. Renaming touches ~8 files.
- No backend batch endpoint: the client loops `/books/lookup` per scanned ISBN. Add one
  only if scanning a shelf is measurably slow.
