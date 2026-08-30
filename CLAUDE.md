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
  Search is not a tab for anyone: it is reached from Library's `+`
  (Scan / Search / Add manually).
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
  Resources/Fonts/  Five bundled Instrument Serif/Sans faces (Google Fonts, SIL OFL),
                    registered via UIAppFonts in Info.plist
  Services/         HTTP clients — one per backend resource (auth, books, sessions...)
  ViewModels/       @Observable view models, one per feature
  Views/            SwiftUI views, one per screen
```

`DesignSystem/` is a hard boundary: `Theme+Color.swift` (semantic roles on a `Palette`
enum, mirrored onto both `Color` and `ShapeStyle`), `Theme+Typography.swift`
(`TypeRole` values — face, size, tracking, and line height together, since SwiftUI's
`Font` carries neither — applied via `.textStyle(_:)`; faces are addressed by
PostScript name, not `.weight()`, because Google ships each Instrument Sans weight as
its own family), `Theme+Layout.swift` (`Spacing`, `Radius`), and `Theme+Surfaces.swift`
(`.cardSurface()` plus the shared components `ReadUpButton`, `UnderlinedField`,
`GenreChip`, `ProgressTrack`). Views reference roles, never values. A raw colour or
font size outside this directory is a regression; these two greps should stay empty
(bar the deliberate one-off glyph sizes noted in `Theme+Typography.swift`):

```sh
grep -rn 'Color(uiColor:' ReadUp --include='*.swift' | grep -v 'DesignSystem/'
grep -rn '\.secundaryLabel\|\.emphasis\b\|\.mainText\|\.backgroundPrimary' \
     ReadUp --include='*.swift' | grep -v 'DesignSystem/'
```

Both exclude `DesignSystem/` itself, which is the one place allowed to name a raw value
or a generated asset symbol — `Palette` is exactly that mapping layer. The colorsets
those symbols point at still exist in `Assets.xcassets/Colors/`, but since Editorial
Cream has no dark mode, `Palette` no longer relies on that asset-catalog indirection —
its roles are literal values (`Color(hex:)`), not generated-symbol lookups.

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
- Commits on this project carry no AI-assistant attribution trailers.
- **Test account.** `dev@readup.test` exists on the production backend purely so debug
  builds don't land in guest mode. Its credentials live in `ReadUp/Secrets.xcconfig`
  (gitignored) as `DEV_EMAIL` / `DEV_PASSWORD`, reach the app through `Info.plist` →
  `AppConfig.devCredentials`, and are consumed by a `#if DEBUG` branch in
  `AuthManager.init()` that signs in whenever there is no Keychain token. Both keys are
  blanked with `[config=Release]` in the xcconfig, so the password is **not** baked into
  a release `Info.plist` — verified by extracting both keys from the built Release app.
  A fresh clone with no `DEV_*` keys simply gets the old behaviour (`devCredentials`
  returns `nil`), so nothing breaks.

  This exists because reinstalling the app — which Xcode does on every run — wipes
  `UserDefaults`, and the `hasLaunchedBefore` guard in `AuthManager.init()` reacts to
  that by deleting the Keychain token. Auto-login was working; the reinstall was
  undoing it.

## Design — Editorial Cream

The app's redesign direction is **Editorial Cream**. It is defined in two places, and
both are reachable from tooling configured in this repository. It is implemented for
the design system and the auth/onboarding flow as of cycle 4
(`.claude/specs/2026-08-29-editorial-cream-design-system.md`,
`.claude/plans/2026-08-29-cycle-4-editorial-cream-and-auth-flow.md`); the remaining
17 of 21 "Screens" artboards inherit the retuned tokens automatically but keep their
existing layouts until a future cycle reworks them individually.

**Figma** — file key `47zjMbONNMeZJ4WFmEe8MC` (file named "ReadUp"). Two pages:

- `Screens` (`0:1`) — 21 artboards at 393×852, the whole app restyled. Section
  `20:729` ("ReadUp — Welcome, Login and Onboarding") holds the four frames cycle 4
  implemented: Welcome `24:82`, Sign in `26:92`, Create account `32:172`, Onboarding
  genres `26:134`.
- `Design System` — one frame `34:230` ("ReadUp — Editorial Cream") under node
  `34:229`, with live specimens for every token: 31 colour variables, 24 text
  styles, the spacing/radius scales, the warm shadow family, and component states.
  Swatches are bound to the variables and specimens are set in the real text styles,
  so the page moves when a token is retuned. Section ids: Colour `34:235`
  (Surfaces `34:239`, Ink `34:277`, Brand & accent `34:325`, Status `34:343`,
  Lines `34:371`), Typography `35:229` (Serif `35:233`, Italic `35:301`,
  Sans `35:314`), Spacing `36:229`, Corners `36:320`, Elevation `36:369`,
  Components `37:229` (specimens `37:233`: Buttons `37:234`, Chips `37:243`,
  Text fields `37:257`, Progress `37:271`, Warning banner `37:290`, Chrome `37:296`).

**Gotcha:** calling the Figma MCP `get_metadata` tool **without a `nodeId`** lists
only the `Screens` page's contents — it silently omits the `Design System` page
entirely. The Design System page is complete and fully reachable, but only when
addressed explicitly by its node id (`34:229`). An earlier pass on this project was
misled by the metadata call's default behavior into believing the page had been
deleted; it had not.

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
  value alone. `cardShadow()` is kept as a deprecated no-op so the screens that still
  call it keep compiling; the calls are removed as those screens are individually
  reworked. Shadow is reserved for things physically stacked: book covers and the
  device.
- **Never a grey.** Anything that reads grey is ink at 9–22% alpha, or a cream step.
- Type is Instrument Serif (content, and every number) + Instrument Sans (interface),
  with italic serif reserved for author names.
- **The tab bar is the one component deliberately not built from Figma.** The
  `Chrome/Tab bar` pill (`16:46`, specimens `37:311`/`37:323`/`37:335`) is
  reference-only: the app uses the **native iOS tab bar**, tinted ink, with the three
  tabs the component defines — Home, Library, Profile. Unselected items keep the system
  colour, the single sanctioned exception to "never a grey".

`DesignSystem/` in the app already routed every screen through semantic tokens, so
adopting the palette was an edit to `Palette` in `Theme+Color.swift` plus the colorsets
in `App/Assets.xcassets/Colors/` — not a per-screen rewrite. Commit `81312d4` is the
proof: it changed the four `DesignSystem/` files and the colorsets, and all 21 screens
restyled without a single one being touched (`xcodebuild` succeeded with zero changed
files under `Views/`).
