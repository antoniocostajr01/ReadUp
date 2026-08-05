# Book Search and Entry — Design

**Date:** 2026-08-05
**Status:** approved, pending implementation plan
**Repositories affected:** `ReadUp` (iOS app) and `ReadUpBackend` (Node/Prisma API)

---

## Problem

Users report that search returns books unrelated to what they typed.

The cause is not Google Books data quality — it is Google's **data model**. The Google Books API indexes *editions* (volumes), not *works*. Every reprint, print-on-demand run, summary and study guide is an independent item in the index, and the popularity signal (`ratingsCount`) is empty on most records. The response simply does not carry enough information to tell "the book the user wants" apart from "generic derivative with a similar title".

`google-books.service.ts` already spends 384 lines reconstructing that missing concept from the outside: exact-phrase `intitle:`/`inauthor:` queries, re-ranking by recency, popularity and language, a regex that discards summaries and study guides, and hand-curated title lists per genre. It still loses, because the missing data is not in the response.

Two collateral problems confirmed during investigation:

- The Google API key is already hitting its daily quota (`RESOURCE_EXHAUSTED`).
- Genre sections do not use real search: they use `genre-seeds.ts`, hand-written title lists resolved one by one. That is permanent manual curation, per genre and per language.

## Solution

Replace the search index with one that has a concept of *work*, and accept that **no single source covers the Brazilian market** — hence three entry paths instead of one.

### API choice — evidence

Tests run against the live APIs, not against documentation.

**Open Library `search.json`, query "harry potter":**

```
1. Harry Potter and the Philosopher's Stone — J. K. Rowling — 23,274 readers
2. Harry Potter and the Chamber of Secrets  — J. K. Rowling —  6,595
3. Harry Potter and the Prisoner of Azkaban — J. K. Rowling —  5,638
```

The seven canonical books, zero fanfic. Search is work-level, and `readinglog_count` is a real popularity signal — exactly what separates the book from its derivatives. Query "sapiens": Harari first with 5,904 readers, the noise below at 26 and 12.

**Genre browsing, `subject:fantasy&sort=readinglog`:** Harry Potter, A Game of Thrones, O Alquimista, 1984 — no noise, with `language:por` working as a filter. This replaces the entire manual curation layer.

| API | Cost | Relevance | Brazilian coverage | Role |
|---|---|---|---|---|
| Open Library | free, no key | excellent (works + popularity) | medium | primary index |
| Google Books | free with key, quota-limited | poor (loose editions) | good | ISBN + fallback |
| ISBNdb | US$ 15–100/month | weak (ISBN database, not a search engine) | good | rejected |
| Hardcover | free (GraphQL) | good | weak, English-centric | rejected |
| Goodreads | — | — | — | API discontinued in 2020 |

### Brazilian ISBN coverage — measurement

ISBN-13s of Brazilian editions were obtained through Google Books, then looked up on Open Library:

| Book | ISBN | Open Library |
|---|---|---|
| O Alquimista | 9788576651857 | found (Rocco) — **no page count** |
| Sapiens | 9788525432186 | found (L&PM) — 464 pages |
| Vidas Secas | 9786552270528 | 404 |
| Dom Casmurro | 9786586490077 | 404 |
| O Pequeno Príncipe | 9798525847606 | 404 |
| A Paciente Silenciosa | 9788501116536 | 404 |
| Torto Arado | 9789896605858 | 404 |

**2 out of 7**, and one of the two hits came back without a page count — the field every progress calculation in ReadUp depends on. In the same test, 5 of 12 titles had no ISBN in **Google's own** records (ebook-only entries).

Design consequence: the scanner is a **chain**, not a source. And being able to correct the data afterwards is not a nice-to-have — it is the normal path for Brazilian books.

---

## Architecture

### Backend — search engine

One orchestrator and two dumb providers:

```
book-search.service.ts      ranks, caches, localizes titles, decides fallback
├── openlibrary.provider    search / subject browse / ISBN lookup
└── google-books.provider   ISBN lookup + free-text search fallback
```

**Removed:** all of `genre-seeds.ts`, the `browse` mode, the `WEIGHTS` table, `resolveSeeds`, `scoreFor` and the title-match bonus. Roughly 250 of the current 384 lines. Open Library already ranks well; rebuilding its ranking from the outside would repeat the mistake that created this problem.

**Kept:** `resolveLanguage` (PT/EN stopwords, decides whether to apply `language:por`) and `normalizeCoverUrl`.

**Filter on Open Library results — three rules:**

1. Drop results with no `author_name`.
2. Drop results with no `cover_i`.
3. If any result has `readinglog_count >= 50`, drop those with `readinglog_count < 5`.

Rule 3 is what kills fanfic and generic derivatives, and it is cheap because the signal already ships in the response.

**Endpoints:**

| Route | Auth | Change |
|---|---|---|
| `GET /books/search` | public | same route, new engine |
| `GET /books/isbn/:isbn` | public | new |

Both routes must be declared **before** `authMiddleware` and **before** `/:id`, otherwise Express matches `isbn` as a book id and demands a token. `book.routes.ts` already documents this care for `/search`.

**Portuguese titles.** Open Library indexes works under their canonical English title. Portuguese editions do exist (20 on the first Harry Potter work) and are resolved through `/works/{key}/editions.json`. Measured cost: 1.9s and 40 KB per work. Resolution is therefore limited to the **top 10 results**, run in parallel, cached.

**Caching.** Two caches, with different justifications:

- **Per work → Portuguese title and cover, TTL 24h.** This is what pays for the 10 extra requests. Without it every search would cost ~4s and 400 KB. A work's Portuguese edition does not change, so a long TTL is safe.
- **Per genre → ready response, TTL 6h.** Genre sections fire on every app launch and are identical for every user of the same genre and language. This is what `seedCache` already does today.

Typed free-text search is **not** cached: every user types something different, hit rate would be low, and stale results carry a real cost.

Both are in-memory `Map`s: they die on deploy and are not shared across instances. Acceptable at current scale; this becomes Redis when it is a measured problem. To be recorded with a `ponytail:` comment.

### App — three entry flows

The `+` button in Library ([Library.swift:48](../../ReadUp/Views/Library.swift)) currently just jumps to the Search tab. It becomes a native `Menu` with three items: **Scan barcode**, **Search**, **Add manually**.

**One form, three entry points.** `BookFormView` is used in every case:

| Entry point | Initial state |
|---|---|
| Manual entry | empty |
| Post-import correction | filled with whatever the API returned |
| Editing from BookDetails | filled with the saved book |

Fields: cover (`PhotosPicker`), title, author, page count, ISBN, description, status. Required: **title** and **page count > 0** — page count because every progress calculation and reading session depends on it.

The backend already supports this editing: `PUT /books/:id` accepts `title`, `author`, `totalPages`, `details`, `coverUrl`, `status` and `progress`, and `LibraryStore.applyUpdate` already knows how to call it. Only the screen is missing.

**An imported book is a copy**, not a mirror of the API. The user edits their own record and nothing overwrites it later. This is what the schema already does.

**Scanner.** `DataScannerViewController` (VisionKit) wrapped in `UIViewControllerRepresentable`, symbologies `.ean13` and `.ean8`. Deployment target is iOS 18.5/26, so it is available with no external dependency. `Info.plist` **has no `NSCameraUsageDescription`** — without that key the app crashes when opening the camera.

Chain after a successful read:

```
scanned ISBN
  → Open Library /isbn/{isbn}.json    (free, no key, no quota)
  → Google Books q=isbn:{isbn}        (better Brazilian edition coverage)
  → BookFormView prefilled with whatever came back, ISBN included
```

### Data

One migration with two changes:

```prisma
model Book {
  isbn       String?             // from the scanner; used for deduplication
  coverImage String? @db.Text    // gallery cover, base64
}
```

**Profile photo needs no work — it is already finished.** Verified on 2026-08-05: the app resizes to 512px, compresses to JPEG at 0.7 and uploads base64 ([Profile.swift:154](../../ReadUp/Views/Profile.swift), [Profile.swift:184](../../ReadUp/Views/Profile.swift)); `PUT /users/me` and `UserService.updateProfile` accept it; `avatarView` renders it; removal works. Migration `20260628000000_add_user_avatar` is applied — `prisma migrate status` reports "Database schema is up to date!". The only pending item is that these files are uncommitted in the working tree.

**User-supplied covers.** Stored in `coverImage` (base64) and served by `GET /books/:id/cover`. When `coverImage` exists, the backend returns `coverUrl = <API>/books/<id>/cover`. That way `BookCoverView` keeps loading an ordinary URL and needs no change.

Rejected alternatives: base64 straight into `coverUrl` would bloat every listing (`GET /books` returns the whole library — 50 books at ~200 KB each would be 10 MB per load); external storage (S3/Supabase) would add infrastructure, credentials and cost before there is a measured need.

### Edge cases

| Situation | Behavior |
|---|---|
| ISBN found in no source | Form opens with the ISBN prefilled and an explanatory notice |
| Camera permission denied | Alert with a shortcut to Settings and a manual-entry option |
| Open Library unavailable | Free-text search falls back to Google Books |
| Book already in the library | Open the existing one instead of duplicating — match by ISBN, else by title + author |
| Cover image too large | Compressed in the app before upload; defensive cap in the backend, same pattern as the avatar |
| Query shorter than 2 characters | Ignored, as today |

---

## Implementation cycles

| # | Cycle | Deliverable |
|---|---|---|
| 0 | Migration + documentation structure | New columns in the database; `.claude/` folders created; test runner wired up |
| 1 | Search engine | Open Library replaces Google in search and genre browsing; ~250 lines removed |
| 2 | Unified form | Manual entry, editing and gallery covers |
| 3 | Scanner | Camera, ISBN chain, fallback to the form |
| 4 | Documentation | Consolidated `CLAUDE.md` in both repositories |

Cycle 0 comes first because it creates the columns cycles 2 and 3 depend on, and the test runner cycle 1 needs.

## Success criteria

- Searching "harry potter" returns the series, with no fanfic or generic derivatives.
- Searching "sapiens" returns Harari's book first.
- Genre sections work with no hand-curated list at all.
- A book can be added with no API involved, using the user's own cover.
- Any field of any book can be corrected afterwards, including imported ones.
- Scanning a Brazilian book's barcode leads to a completed entry — with API data when it exists, with a prefilled form when it does not.

## Documentation structure

```
CLAUDE.md              repository root (Claude Code convention)
.claude/
  specs/               design docs — this document is the first
  plans/               plan per cycle, with per-step status
  handoff/             what changed in each cycle: files, decisions, open items
  skills/              project skills
```

`ReadUpBackend` is a separate repository and gets its own `CLAUDE.md`. Handoffs spanning both live here, referencing the commit on the other side.

All documentation in this repository is written in English.
