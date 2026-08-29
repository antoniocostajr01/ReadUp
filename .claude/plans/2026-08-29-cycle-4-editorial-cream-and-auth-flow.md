# Cycle 4 — Editorial Cream Design System and Auth Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Retune the app's token layer to the Editorial Cream direction and rebuild
the four auth/onboarding screens that carry the redesign's launch impression —
Welcome, Sign in, Create account, and Genre onboarding — to the matching Figma
frames. Every other screen inherits the new tokens automatically and is out of scope
for this cycle.

**Architecture:** `DesignSystem/` is already the app's hard boundary
(`c74fa2f`), so this cycle is a values-only retune of that layer plus new shared
primitives the auth flow needs (`ReadUpButton`, `UnderlinedField`, `GenreChip`,
`ProgressTrack`), followed by four screens rebuilt on top of it. No other screen
under `Views/` or `Components/` needs to change — this is also this cycle's proof
that the token indirection built in cycle "Add semantic design system" was worth it.

**Tech Stack:** SwiftUI/`@Observable`, no new dependencies except two bundled font
families (Instrument Serif, Instrument Sans; Google Fonts, SIL OFL) and their
`.ttf` files under `ReadUp/Resources/Fonts/`.

**Spec:** [`.claude/specs/2026-08-29-editorial-cream-design-system.md`](../specs/2026-08-29-editorial-cream-design-system.md)

## Global Constraints

- **Branch `feat/editorial-cream-auth-flow`, off `main` at `ae83d52`.** Repository:
  `/Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp`.
- **Design source of truth:** Figma file `47zjMbONNMeZJ4WFmEe8MC`. The "Design
  System" page (`34:229`) and the "Screens" page (`0:1`, section `20:729` for this
  cycle's four frames) are both live and complete — but calling the Figma MCP's
  `get_metadata` **without a `nodeId`** lists only the `Screens` page's contents. An
  earlier pass on this project was misled by that into believing the Design System
  page had been deleted; it had not — it just has to be addressed explicitly by its
  node id (`34:229`).
- **No screen restyle should require touching a non-DesignSystem file.** If
  implementing a token change forces an edit under `Views/` or `Components/` outside
  the four screens this cycle owns, that is a signal the token was not actually
  semantic — stop and fix the role, not the call site.
- **`cardShadow()` becomes a deprecated no-op**, not a deletion. Screens outside this
  cycle's four still call it; removing the function would be a build break across the
  whole app for zero benefit this cycle. It is removed from call sites only as those
  screens are individually reworked in future cycles.
- **Faces are addressed by PostScript name, not `.weight()`.** See the spec's
  "Fonts bundled" decision — this is not optional, `.weight()` silently no-ops on
  these bundled families.
- Code comments follow the existing codebase convention: **Portuguese**. `.md`
  files: **English**.
- No XCTest target exists in this project (unchanged from cycle 2). Verification is
  a clean `xcodebuild` plus targeted runtime checks (font resolution, bundle
  contents), not an invented test target.

## File Structure

| File | Change |
|---|---|
| `ReadUp/Resources/Fonts/*.ttf` (5 files) | new — bundled Instrument faces |
| `ReadUp/Info.plist` | `UIAppFonts` entries for the 5 faces |
| `ReadUp/DesignSystem/Theme+Color.swift` | rewritten — 31 roles, line roles as `ink.opacity()` |
| `ReadUp/DesignSystem/Theme+Typography.swift` | rewritten — `Face`, `TypeRole`, 24 roles |
| `ReadUp/DesignSystem/Theme+Layout.swift` | rewritten — `Spacing` (3 gutters), `Radius`, `Motion`, `Elevation`, `coverShadow()`, deprecated `cardShadow()` |
| `ReadUp/DesignSystem/Theme+Surfaces.swift` | rewritten — `.textStyle()`, `ReadUpButton`, `UnderlinedField`, `GenreChip`, `ProgressTrack` |
| `App/Assets.xcassets/Colors/*.colorset` (8 colorsets) | retargeted to the new literal values |
| `ReadUp/App/TabBar.swift` | rebuilt — floating pill in a `safeAreaInset` |
| `ReadUp/Views/Onboarding/WelcomeView.swift` | rebuilt to Figma `24:82` |
| `ReadUp/Views/Auth/LoginView.swift` | rebuilt to Figma `26:92` |
| `ReadUp/Views/Auth/CreateAccountView.swift` | rebuilt to Figma `32:172` |
| `ReadUp/Views/Onboarding/GenreOnboardingView.swift` | rebuilt to Figma `26:134`, keeps `GenrePhysicsScene` |
| `ReadUp/Localizations/Localization+Auth.swift` | new/changed keys for the rebuilt auth copy |
| `ReadUp/Localizations/Localization+Onboarding.swift` | new/changed keys for the rebuilt onboarding copy |
| `ReadUp/Localizable.xcstrings` | new keys, en + pt-BR |

---

### Phase 0: Branch

- [x] `git checkout -b feat/editorial-cream-auth-flow` off `main` at `ae83d52`.

---

### Phase 1: Design system retune (DONE — commit `81312d4`)

**Files:** `ReadUp/Resources/Fonts/*`, `ReadUp/Info.plist`,
`ReadUp/DesignSystem/Theme+Color.swift`, `Theme+Typography.swift`,
`Theme+Layout.swift`, `Theme+Surfaces.swift`, `App/TabBar.swift`, 8 colorsets.

**Interfaces:**
- Consumes: Figma variables/text styles from node `34:229`, `tokens/*.css` from
  Claude Design project `f7b730f5-68da-495c-af46-51e4a19b0003`.
- Produces: every role the four Phase 2 screens are built against —
  `Palette.*`, `TypeRole.*` / `Font.*`, `Spacing.*`, `Radius.*`, `Motion.*`,
  `Elevation`, `.textStyle(_:)`, `ReadUpButton`, `UnderlinedField`, `GenreChip`,
  `ProgressTrack`, `ReadUpTabBar`.

- [x] **Step 1: Bundle the five font faces and register them**

  `ReadUp/Resources/Fonts/InstrumentSans-{Regular,Medium,SemiBold}.ttf`,
  `InstrumentSerif-{Regular,Italic}.ttf` added; `UIAppFonts` added to
  `ReadUp/Info.plist` listing all five filenames.

- [x] **Step 2: Rewrite `Theme+Color.swift`**

  31 roles under Surfaces / Ink / Brand & accent / Status / Lines. `brand` set equal
  to `ink` (no chromatic brand fill). `accentProgress` is the single chromatic
  role. All six `line/*` roles expressed as `ink.opacity(_:)` at ascending alpha
  (0.09 → 0.22) rather than independent literals. No dark-mode variants — every
  role is a literal `Color(hex:)`, since there is no dark mode in this system.

- [x] **Step 3: Rewrite `Theme+Typography.swift`**

  `Face` holds the 5 PostScript names. `TypeRole` carries `face`, `size`,
  `lineHeight` (multiplier), `tracking` (percent of size, per Figma's convention),
  `relativeTo` (for Dynamic Type). 24 roles across Serif / Italic serif / Sans.
  `trackingPoints` and `lineSpacingPoints` computed properties do the
  percent-to-points and multiplier-to-gap conversions in one place. A `Font`
  extension mirrors each role's face+size for call sites that only take a `Font`.

- [x] **Step 4: Rewrite `Theme+Layout.swift`**

  `Spacing` gains three named gutters — `gutterList` (20, list screens),
  `gutterDetail` (24, detail screens), `gutterAuth` (28, auth/onboarding) — plus
  chrome constants (`tabBarHeight` 62, `tabBarInset` 20,
  `contentBottomWithTabBar` 110). `Radius` gains the full corner scale
  (`coverSm` 4 → `pill` 999) with the app's old generic names (`sm`/`md`/`lg`/`xl`)
  kept as deprecated aliases onto it. `Motion` defines the one easing curve at four
  durations. `Elevation` defines the warm brown-black shadow family
  (`#3C301E` / `#281E10`) for `coverShadow(_:)`. `cardShadow()` is marked
  `@available(*, deprecated)` and does nothing — kept so the ~17 screens that still
  call it keep compiling; removed from a screen only when that screen is reworked.

- [x] **Step 5: Rewrite `Theme+Surfaces.swift`**

  `.textStyle(_:)` applies font + tracking + line spacing together (the fix for
  `Font` not carrying tracking/line-height). `.cardSurface(radius:)` /
  `.fillSurface(radius:)` stay as background helpers. Four new primitives built to
  the Figma specimens' measured sizes: `ReadUpButton` (primary/secondary/
  tertiary/danger variants, verb-phrase labels), `UnderlinedField` (line at
  `fieldLine` 22% at rest, `fieldLineActive` solid ink on focus — the entire focus
  treatment), `GenreChip` (inversion on selection: cream chip → solid ink fill,
  cream text at weight 500), `ProgressTrack` (3pt tall, 2pt radius, amber on
  ink-12% track).

- [x] **Step 6: Rebuild `TabBar.swift`**

  `ReadUpTabBar`: a floating pill, 62pt tall, `surfaceChrome` (ink at 94%) fill,
  31pt radius (via `Capsule`), inset 20pt from each side and 22pt from the bottom
  (`Spacing.sheetInset`). Placed in a `.safeAreaInset(edge: .bottom)` on the root
  `TabView` so no individual screen needs its own bottom padding to clear it, and
  the native tab bar is hidden via `.toolbar(.hidden, for: .tabBar)`.

- [x] **Step 7: Retarget the 8 colorsets**

  `Background Primary`, `Component Background`, `Emphasis`, `Main Text`,
  `Secundary Label`, `TabBar Background`, `Week Day Background`,
  `Week Day Component` — updated to the new literal values so any remaining
  generated-asset call site (there are none outside `DesignSystem/`, confirmed by
  grep) would render correctly if one existed.

- [x] **Step 8: Verify**

  ```bash
  xcodebuild -project ReadUp.xcodeproj -scheme ReadUp \
    -destination 'platform=iOS Simulator,name=iPhone 17' build
  ```

  Result: `BUILD SUCCEEDED`, with **zero changed files under `Views/`** — the proof
  that every screen already routed through the semantic token layer. All five
  bundled faces confirmed resolvable by PostScript name via `CTFontManager`; the
  `.ttf` files and the `UIAppFonts` entries confirmed present in the built app
  bundle.

- [x] **Step 9: Commit**

  ```bash
  git add ReadUp/DesignSystem ReadUp/App/TabBar.swift ReadUp/Resources/Fonts \
          ReadUp/Info.plist "ReadUp/Assets.xcassets/Colors"
  git commit -m "Implement the Editorial Cream design system"
  ```

  Landed as `81312d4`.

---

### Phase 2: The four screens (IN PROGRESS)

Ran as four parallel agents, one per screen, on disjoint files — no shared file
between them, so no merge coordination was needed beyond the shared
`Localizable.xcstrings` and the two `Localization+*.swift` files.

**Files (one agent each):**
- `ReadUp/Views/Onboarding/WelcomeView.swift` — Figma `24:82`
- `ReadUp/Views/Auth/LoginView.swift` — Figma `26:92`
- `ReadUp/Views/Auth/CreateAccountView.swift` — Figma `32:172`
- `ReadUp/Views/Onboarding/GenreOnboardingView.swift` — Figma `26:134`

**Interfaces:**
- Consumes: every role from Phase 1 (`Palette.*`, `TypeRole.*`, `ReadUpButton`,
  `UnderlinedField`, `GenreChip`, `Spacing.gutterAuth`, `Radius.*`).
- Produces: the rebuilt screens themselves. `WelcomeView` additionally keeps its
  existing entry point into `authManager.enterGuestMode()` (see the spec's
  "Guest mode kept" decision); `GenreOnboardingView` keeps `GenrePhysicsScene`
  unchanged apart from restyling `GenreChip`'s texture.

- [ ] **Step 1: `WelcomeView` — Figma `24:82`**

  Rebuild on `titleXL` / `displayHero`, `ReadUpButton` primary + secondary, and add
  a third tertiary "Continue as guest" action (not in the Figma frame, kept for
  `enterGuestMode()` reachability — see spec).

- [ ] **Step 2: `LoginView` — Figma `26:92`**

  Rebuild on `UnderlinedField` for email/password, `ReadUpButton` primary for
  submit, secondary for the Apple/Google providers.

- [ ] **Step 3: `CreateAccountView` — Figma `32:172`**

  Rebuild on `UnderlinedField`. Keep `lastName` dropped (per spec), keep Confirm
  password and the terms-acceptance gate (product/legal, not visual — per spec).

- [ ] **Step 4: `GenreOnboardingView` — Figma `26:134`**

  Restyle `GenreChip` usages inside `GenrePhysicsScene` to the new token; keep the
  SpriteKit drop-physics interaction (per spec's "GenrePhysicsScene kept"
  decision). Rebuild the surrounding chrome (title, `ProgressTrack` if used,
  continue button) on the new roles.

- [ ] **Step 5: Localization**

  Add the new/changed keys each screen needs to
  `ReadUp/Localizations/Localization+Auth.swift` and
  `Localization+Onboarding.swift`, and to `ReadUp/Localizable.xcstrings` in both
  `en` and `pt-BR`. Validate JSON:

  ```bash
  node -e "JSON.parse(require('fs').readFileSync('ReadUp/Localizable.xcstrings','utf8')); console.log('valid')"
  ```

- [ ] **Step 6: Build**

  ```bash
  xcodebuild -project ReadUp.xcodeproj -scheme ReadUp \
    -destination 'platform=iOS Simulator,name=iPhone 17' build
  ```

  Expected: `BUILD SUCCEEDED`.

- [ ] **Step 7: Commit**

  One commit per screen (matching the parallel-agent split), or one combined commit
  for Phase 2 if merged together — whichever the executing agents actually did.

---

### Phase 3: Localization and documentation

- [ ] **Step 1: Confirm the 18 new keys are complete in both languages**

  Cross-check every key referenced by the four Phase 2 screens exists in
  `Localizable.xcstrings` under both `en` and `pt-BR`, `state: "translated"`.

- [ ] **Step 2: Write the handoff**

  `.claude/handoff/2026-08-29-cycle-4-editorial-cream-and-auth-flow.md`, from real
  build output and the actual diffs Phase 2 produced — not a restatement of this
  plan. Written after Phase 2 lands, by whoever verifies the final build.

- [ ] **Step 3: `CLAUDE.md`**

  Update the "Design — Editorial Cream" section to describe the system as
  implemented (this cycle) rather than planned, and correct the closing paragraph's
  future tense now that the retune has actually happened.

---

## Done when

- `xcodebuild` succeeds with the four Phase 2 screens rebuilt and zero other files
  under `Views/`/`Components/` touched.
- All five bundled faces resolve by PostScript name at runtime.
- Guest mode (`enterGuestMode()`) and `GenrePhysicsScene` remain reachable and
  functional.
- `Localizable.xcstrings` stays valid JSON with full en/pt-BR coverage for every
  new key.
- `.claude/handoff/2026-08-29-cycle-4-editorial-cream-and-auth-flow.md` exists,
  written from real output, once Phase 2 and 3 land.
- `CLAUDE.md`'s design section matches reality, not a future plan.
