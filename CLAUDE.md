# ReadUp

ReadUp is an iOS app that helps users build and keep a reading habit: tracking reading
sessions, organizing a personal library, setting goals, and turning progress into
something rewarding rather than a chore.

This repository is the **iOS app** (SwiftUI). The backend — API, database, and the
book-search engine — lives in a separate repository, `ReadUpBackend`, currently at
`../ReadUpBackend` on disk relative to this one.

## What the app currently does

- **Accounts.** Email/password and Sign in with Apple, password reset, guest access to
  parts of the app (`ReadUp/Views/Auth/`, `AuthManager`, `AuthService`).
- **Library.** Users track books through statuses (reading, read, want to read,
  abandoned, rereading) with page-level progress (`LibraryStore`, `Models/Book.swift`).
- **Reading sessions.** Timed sessions logging pages read and thoughts, summarized at
  the end with a shareable image card (`ReadingSession`, `SessionSummary`,
  `SessionSummaryShareCard`).
- **Book search.** `Search` proxies through the backend, which indexes Open Library
  (work-level search, so a query returns the actual books people mean, not every
  loose edition and derivative) with Google Books as a fallback.
  See `.claude/specs/2026-08-05-book-search-and-entry-design.md` for why.
  Search is not a tab: it is reached from Library's `+` (Scan / Search / Add manually),
  and only guests still see a Search tab.
- **Barcode scanning.** `ISBNScanView` scans book barcodes in batch (VisionKit
  `DataScannerViewController`) and resolves each ISBN through `GET /books/lookup`, which
  uses Open Library's edition record (`/isbn/{isbn}.json` — exact, unlike a text search
  for `isbn:`) with Google Books as fallback.
- **Genre discovery.** Curated genre shelves on the Search screen, backed by the same
  Open Library engine — no hand-maintained title lists.
- **Profile.** Editable display name and a profile photo (picked from the library,
  resized and compressed client-side, stored as base64 on the backend).
- **AI reading assistant.** A chat surface scoped to literary discussion, with a
  client-side topic classifier plus a backend guardrail so the assistant stays on
  topic (`LiteraryTopicClassifier`, `AIChatView`, `LiteraryAssistantViewModel`).
- **Onboarding.** Genre selection on first launch, used to seed genre shelves and
  personalize the home screen.
- **Localization.** English and Portuguese via `Localizable.xcstrings`, with one
  `Localization+<Area>.swift` file per feature area under `ReadUp/Localizations/`.

Data persistence moved from local SwiftData storage to the backend/database — the app
is online-only. There is no offline local store to reconcile.

## Project structure

```
ReadUp/
  App/             Entry point, root navigation, tab bar
  Components/      Small reusable views (cards, cover art, stat tiles)
  Extensions/       SwiftUI/Foundation extensions
  Localizations/    One file per feature area, backed by Localizable.xcstrings
  Models/           Codable types mirroring the backend's DTOs
  Services/         HTTP clients — one per backend resource (auth, books, sessions...)
  ViewModels/       @Observable view models, one per feature
  Views/            SwiftUI views, one per screen
```

Services mirror backend resources 1:1 (`BookService` ↔ `/books`, `AuthService` ↔
`/auth` and `/users/me`, etc.) — when the backend's response shape changes, the
matching `Codable` model in `Models/` is where that shows up first.

## `.claude/` — how this project is developed

This project uses [Claude Code Superpowers](https://github.com/obra/superpowers) for
feature work: a design is brainstormed and written down before a plan is written, and
a plan is written before any code changes. See `.claude/skills/README.md` for exactly
which skills fire and when.

```
.claude/
  specs/     Design docs. One per feature, written and approved BEFORE implementation.
             Captures the problem, the options considered, the decision, and why —
             including evidence (measurements, API comparisons) where the decision
             wasn't obvious.
  plans/     Step-by-step implementation plans derived from an approved spec. Broken
             into small TDD tasks: exact files, exact code, exact test cases. One plan
             per development cycle.
  handoff/   What actually happened in each cycle: files touched, decisions made
             during implementation that the plan didn't already cover, what was
             verified and how, and what was deliberately left out. Written after the
             fact, from real command output — not a restatement of the plan.
  skills/    Which Superpowers (and project-local) skills this project's workflow
             uses, and why. Not a copy of the skills themselves.
```

Reading order for picking up a past piece of work: find its entry in `handoff/`, follow
the link back to the `plans/` file it executed, follow that back to the `specs/` file
it implements. The handoff is the fastest path to "what changed and why"; the spec is
the fastest path to "why this approach and not another one."

`ReadUpBackend` is a separate repository and keeps its own `CLAUDE.md` and (pending)
its own `.claude/` structure — not yet created as of this writing. Work that spans both
repositories is recorded in this repository's `.claude/handoff/`, referencing the
backend commit by short SHA.

## Working conventions

- All `.md` files in this project — specs, plans, handoffs, this file — are written in
  **English**, regardless of what language the conversation with the user happens in.
- Code comments follow the existing codebase convention: **Portuguese**.
- Backend `DATABASE_URL` points at a production Supabase database. Schema changes go
  through `prisma migrate dev --create-only` to generate, a manual read of the
  generated SQL, then `prisma migrate deploy` to apply — never `migrate dev` without
  `--create-only`, and never `migrate reset` or `db push`.
