# Cycle 1 — Open Library search engine

**Date:** 2026-08-05
**Plan:** [`.claude/plans/2026-08-05-cycle-1-open-library-search.md`](../plans/2026-08-05-cycle-1-open-library-search.md)
**Spec:** [`.claude/specs/2026-08-05-book-search-and-entry-design.md`](../specs/2026-08-05-book-search-and-entry-design.md)

## What shipped

`GET /books/search` is now served by Open Library instead of Google Books, for both
free-text search and genre shelves. Google Books survives only as a fallback. The
iOS app was not modified and did not need to be — the HTTP contract is unchanged.

## Files touched

All in **ReadUpBackend**, branch `feat/open-library-search`.

| Commit | Change |
|---|---|
| `00d55b0` | `npm test` script (`tsc && node --test`) + `src/services/search/ttl-cache.ts` |
| `60dfe18` | `src/services/search/language.ts` — PT/EN resolution moved out of the old engine, tested for the first time |
| `b4df2c3` | `src/services/search/openlibrary.provider.ts` — search, subject browse, DTO mapping, the three filter rules; `src/dtos/book.dto.ts` trimmed |
| `57f7884` | `localizedEdition()` — Portuguese edition titles and covers |
| `0e4d60e` | `src/services/search/book-search.service.ts` + `google-books.provider.ts` — orchestration, caches, fallback |
| `8179a8a` | `src/controllers/book.controller.ts` rewired; **deleted** `google-books.service.ts` (384 lines) and `genre-seeds.ts` (124 lines) |

Net: 520 lines deleted, 36 tests added where there had been none.

## Decisions made during implementation

- **Caches are instance fields, not module-level.** Module scope broke test isolation.
  Production behavior is identical: `book.routes.ts` constructs one `BookController`,
  hence one `BookSearchService`, per process — so the cache is still shared across
  all requests.
- **Over-fetch factor of 2.** The filter discards results, so a full page from Open
  Library would arrive short, and the app reads a short page as "no more results"
  and stops its infinite scroll. Pages may now repeat an item; the app already
  deduplicates by id.
- **`%20` instead of `+` for spaces in query strings.** An implementer introduced this
  believing it fixed a bug in the provider. It did not — both encodings were verified
  against the live API and return identical results (`numFound` 86061 for
  `subject:"science fiction"` either way). The actual flaw was in a test assertion that
  used `decodeURIComponent`, which does not decode `+` to a space. The change was kept
  because it is harmless and more explicit, but the reasoning recorded in
  `task-3-report.md` is wrong and should not be cited as precedent.

## What was verified

Live, against the running server and the real Open Library API.

**The search that motivated the whole cycle:**

```
$ curl "localhost:3000/books/search?q=harry%20potter&lang=pt&maxResults=8"
Harry Potter e a Pedra Filosofal
Harry Potter and the Chamber of Secrets
Harry Potter e o Prisioneiro de Azkaban
Harry Potter e as Relíquias da Morte
Harry Potter e o cálice de fogo
Harry Potter and the Order of the Phoenix
Harry Potter e o enigma do Príncipe
Harry Potter e a Criança Amaldiçoada - Parte Um e Dois
```

Eight real Harry Potter books. No fanfic, no study guides, no unrelated volumes.

**Second success criterion:**

```
$ curl "localhost:3000/books/search?q=sapiens&lang=pt&maxResults=3"
Sapiens
Simon vs. a agenda Homo Sapiens
```

Harari first. The second title also shows `localizedEdition` working — Open Library
indexes that work as "Simon vs. the Homo Sapiens Agenda".

**Genre shelves with no curated list in the repository:**

```
$ curl "localhost:3000/books/search?q=subject:fantasy&mode=browse&lang=pt&maxResults=6"
Harry Potter e a Pedra Filosofal
A Guerra dos Tronos
O Alquimista
Corte de névoa e fúria
1984
The Hunger Games
```

`genre-seeds.ts` no longer exists. This is entirely Open Library's `sort=readinglog`.

**Cache:**

```
cold:   5.135788s
cached: 0.001765s
```

**Test suite:** `npm test` → `tsc` with 0 errors, 36/36 passing.

## Open items

- **Open Library is flaky, and the fallback is worse than it looks.** During
  verification a request hit a 10s connect timeout to `openlibrary.org`, the service
  fell back to Google Books as designed, and Google returned exactly the kind of noise
  that motivated this migration — "RIGHT OF SAPIENS" and "DUTY OF SAPIENS" by an
  obscure author, with Harari absent. Retrying returned correct results three times in
  a row, so it is intermittent. The resilience worked; the quality of what it falls
  back to did not. Worth considering: one retry against Open Library before conceding
  to Google.
- **Cold genre shelves take ~5s.** That is the localization cost — ten parallel
  `editions.json` calls. Cached calls are instant, and shelves are identical for every
  user of the same genre and language, so most users hit the cache. If it still feels
  slow in the app, the lever is `LOCALIZE_LIMIT` (currently 10), not the cache.
- **Some titles stay in English.** *Chamber of Secrets* and *Order of the Phoenix* came
  back untranslated: no Portuguese edition appeared within the first 50 editions of
  those works. Raising `EDITIONS_LIMIT` would cost a larger payload per work.
- **`GET /books/isbn/:isbn` was not built.** It belongs to cycle 3 (the barcode
  scanner). When it is added, it must be declared before `authMiddleware` and before
  `/:id` in `book.routes.ts`, or Express will match `isbn` as a book id and demand a
  token.
- **The branch is not merged.** `feat/open-library-search` is ahead of `main` in
  ReadUpBackend by 7 commits.
