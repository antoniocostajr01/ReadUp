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
.mcp.json          MCP servers this project needs (Figma). Project-scoped, committed.
ReadUp/
  App/             Entry point, root navigation, tab bar
  Components/      Small reusable views (cards, cover art, stat tiles)
  DesignSystem/     Semantic design tokens — the only place raw colour, type,
                    spacing and radius values are allowed to appear
  Extensions/       SwiftUI/Foundation extensions
  Localizations/    One file per feature area, backed by Localizable.xcstrings
  Models/           Codable types mirroring the backend's DTOs
  Services/         HTTP clients — one per backend resource (auth, books, sessions...)
  ViewModels/       @Observable view models, one per feature
  Views/            SwiftUI views, one per screen
```

`DesignSystem/` is a hard boundary: `Theme+Color.swift` (semantic roles on a `Palette`
enum, mirrored onto both `Color` and `ShapeStyle`), `Theme+Typography.swift` (named type
roles built on semantic text styles, so Dynamic Type keeps working),
`Theme+Layout.swift` (`Spacing`, `Radius`), and `Theme+Surfaces.swift` (`.cardSurface()`).
Views reference roles, never values. A raw colour or font size outside this directory is
a regression; these two greps should stay empty (bar the deliberate one-off glyph sizes
noted in `Theme+Typography.swift`):

```sh
grep -rn 'Color(uiColor:' ReadUp --include='*.swift' | grep -v 'DesignSystem/'
grep -rn '\.secundaryLabel\|\.emphasis\b\|\.mainText\|\.backgroundPrimary' \
     ReadUp --include='*.swift' | grep -v 'DesignSystem/'
```

Both exclude `DesignSystem/` itself, which is the one place allowed to name a raw value
or a generated asset symbol — `Palette` is exactly that mapping layer.

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

## Design — Editorial Cream

The app's redesign direction is **Editorial Cream**. It is defined in two places, and
both are reachable from tooling configured in this repository.

**Figma** — file key `47zjMbONNMeZJ4WFmEe8MC` (file named "ReadUp"). Two pages:

- `Screens` — 21 artboards at 393×852, the whole app restyled.
- `Design System` — live specimens for every token: 31 colour variables, 24 text
  styles, the spacing/radius scales, the warm shadow family, and component states.
  Swatches are bound to the variables and specimens are set in the real text styles,
  so the page moves when a token is retuned.

The Figma MCP server is declared in `.mcp.json` at the root of this repository, so it
is committed with the project and anyone who clones it gets the connection. Claude Code
asks for a one-time approval before using a project-scoped server, and the OAuth login
is per machine — no credentials live in the file.

**Claude Design** — project `f7b730f5-68da-495c-af46-51e4a19b0003` ("ReadUp UI
Redesign"), read via the `DesignSync` tool after `/design-login`. It holds `tokens/`
(the CSS source of truth every Figma variable was lifted from), `guidelines/`,
`components/`, and `ui_kits/`. Note it is a **regular** project, not a design-system
project, so `DesignSync list_projects` does not show it — address it by id.

`DesignSync get_file` truncates at 256 KB, which is larger than every cover in
`assets/books/`. Those four PNGs cannot be retrieved through it; they have to arrive
some other way. Figma covers are typeset placeholders until they do.

### What Editorial Cream changes about the current app

- **The green is retired.** `brand` is ink `#171512`; the primary button, selected
  chip, tab bar and checkbox are all ink. Amber `#F3B54A` is the only chromatic
  colour and is reserved for progress fills and week bars.
- **No dark mode.** Night is a place, not a theme — the scanner is the only dark
  screen. Everything else is cream, always.
- **Cards carry no shadow.** A card is `surface/raised` on `surface`, separated by
  value alone. `cardShadow()` is deliberately dropped. Shadow is reserved for things
  physically stacked: book covers and the device.
- **Never a grey.** Anything that reads grey is ink at 9–22% alpha, or a cream step.
- Type is Instrument Serif (content, and every number) + Instrument Sans (interface),
  with italic serif reserved for author names.

`DesignSystem/` in the app already routes every screen through semantic tokens, so
adopting the palette is an edit to `Palette` in `Theme+Color.swift` plus the colorsets
in `App/Assets.xcassets/Colors/` — not a per-screen rewrite.
