# Cycle 4 — Editorial Cream design system + welcome/login/onboarding flow

Executed 2026-08-29 on branch `feat/editorial-cream-auth-flow`, two commits off
`main` (`ae83d52`). Spec: `.claude/specs/2026-08-29-editorial-cream-design-system.md`.
Plan: `.claude/plans/2026-08-29-cycle-4-editorial-cream-and-auth-flow.md`.
iOS repository only — `ReadUpBackend` was not touched.

## What shipped

The Editorial Cream direction, implemented as real tokens (`81312d4`), and the four
screens of the auth/onboarding flow rebuilt on top of them (`96c151c`).

## Files touched

**`81312d4` — the design system.** No file under `Views/` or `Components/` changed;
that was the point of the commit and the check that it held.

- `ReadUp/Resources/Fonts/` (new) — five faces from Google Fonts (SIL OFL):
  `InstrumentSerif-Regular/Italic`, `InstrumentSans-Regular/Medium/SemiBold`.
- `ReadUp/Info.plist` — `UIAppFonts` added (the key did not exist).
- `DesignSystem/Theme+Color.swift` — rewritten. 31 semantic roles, values lifted from
  the Figma variables on `34:230`. `Color(hex:)` initializer added. The six line roles
  are `ink.opacity(_:)` rather than literals.
- `DesignSystem/Theme+Typography.swift` — rewritten. `Face` (PostScript names),
  `TypeRole` (face + size + line height + tracking), 24 roles, plus `Font` mirrors and
  two deprecated aliases (`bodySupportingStrong`, `captionStrong`) kept so untouched
  screens still compile.
- `DesignSystem/Theme+Layout.swift` — rewritten. `Spacing` (three gutters), `Radius`,
  `Motion`, `Elevation`, `coverShadow(_:)`. `cardShadow()` demoted to a deprecated
  no-op returning `self`.
- `DesignSystem/Theme+Surfaces.swift` — `.textStyle(_:)`, plus `ReadUpButton`,
  `UnderlinedField`, `GenreChip`, `ProgressTrack`.
- `App/TabBar.swift` — the native tab bar hidden, replaced by `ReadUpTabBar`, a
  floating ink pill in a `safeAreaInset`.
- `App/Assets.xcassets/Colors/*` — the eight colorsets retargeted to cream in both
  appearance slots.

**`96c151c` — the flow.**

- `Views/Onboarding/WelcomeView.swift` — rewritten; carousel, `OnboardingPage`,
  `OnboardingPageView`, `FannedCovers` deleted.
- `Views/Auth/LoginView.swift` — rewritten.
- `Views/Auth/CreateAccountView.swift` — rewritten; `TermsView` kept and restyled.
- `Views/Onboarding/GenreOnboardingView.swift` — header, footer, and `chipView`
  restyled. `GenrePhysicsScene.swift` **unmodified**, as decided.
- `Views/Auth/AppleSignIn.swift` (new) — `AppleSignInCoordinator`.
- `Localizable.xcstrings` — 18 keys added (en + pt-BR), 5 orphaned carousel keys
  removed. 235 keys total.
- `Localizations/Localization+Auth.swift`, `+Onboarding.swift` — cases added; the five
  carousel cases removed.
- `CLAUDE.md`, `.claude/specs/`, `.claude/plans/`.

`AuthManager` was not modified. `signIn`, `signUp`, `signInWithApple(result:)`,
`enterGuestMode`, `completeOnboarding(with:)` and `SessionPhase` all keep their
signatures, so `RootView`'s phase switch needed no change.

## Decisions made during implementation, not in the plan

**The Figma "Design System" page was not missing — the tool call was wrong.** An early
pass called `get_metadata` with no `nodeId`, which returns only the `Screens` page, and
concluded from that the Design System page had been deleted. It exists at `34:229`,
complete, and had to be addressed by id. The first draft of this cycle's plan contained
a wrong instruction to "correct" CLAUDE.md accordingly; the user caught it. The gotcha
is now recorded in CLAUDE.md so the same conclusion is not reached twice.

**`TextStyle` collided with `Font.TextStyle`.** The type carrying a full type role was
first called `TextStyle`; inside `extension Font`, `TextStyle.displayHero` resolves to
`Font.TextStyle` and the build failed with 26 "has no member" errors. Renamed to
`TypeRole`.

**Figma's `letterSpacing` is a percentage of font size, not points.** `UI/Overline`
reports `14`, which is 0.14em ≈ 1.54pt at 11pt — not 14pt. Confirmed against
`--track-overline: 0.14em` in the Claude Design CSS. The conversion lives in
`TypeRole.trackingPoints` so no call site can get it wrong.

**Instrument Sans weights are separate font families.** Google ships
`InstrumentSans-Medium.ttf` with family name "Instrument Sans Medium" and subfamily
"Regular", so `.weight(.medium)` on a custom font cannot reach it. Faces are addressed
by PostScript name in `Face`. Verified with `CTFontCopyPostScriptName` before relying
on it.

**`ignoresSafeArea()` was applied to the whole view rather than the background.** Caught
by screenshotting the running app, not by the build: the Welcome covers rendered under
the Dynamic Island. Fixed in all three affected screens to
`.background(Color.surface.ignoresSafeArea())`.

**The Sign in with Apple overlay trick did not work.** The first implementation put a
`SignInWithAppleButton` at `opacity(0.011)` under a styled `ReadUpButton` — low enough
to look hidden, non-zero so hit testing survives. On screen the native control was
plainly visible ghosting through. Replaced with `AppleSignInCoordinator`, which drives
`ASAuthorizationController` directly from a real `ReadUpButton`. Same
`authManager.signInWithApple(result:)` call.

**Localization was done before the screens, not after.** The plan had it last. Adding
the enum cases first meant each screen agent's file could be compiled and verified on
its own instead of every screen being un-buildable until a final pass.

**`completeOnboarding(with: [])` is safe for "Skip for now".** Checked rather than
assumed: it calls `updateGenres([])`, PUTs the empty array, and sets `phase = .ready`.
No client-side non-empty guard.

## What was verified

- `xcodebuild -scheme ReadUp -destination 'id=43275BCF…' -derivedDataPath build/DD build`
  → `** BUILD SUCCEEDED **`, after each of the two commits.
- After `81312d4`, `git status --porcelain` showed changes only under `DesignSystem/`,
  `App/TabBar.swift`, `Info.plist`, `Assets.xcassets/Colors/` and the new
  `Resources/`. **Nothing under `Views/` or `Components/`.** This is the evidence that
  the token layer from `c74fa2f` did what it was built for: 21 screens restyled by
  editing four files.
- The five faces register and resolve by PostScript name — a `CTFontManager` script
  registered each `.ttf` and compared `CTFontCopyPostScriptName` to the string in
  `Face`; 5/5 exact matches.
- `find build/DD/Build/Products -name '*.ttf' -path '*ReadUp.app*'` → all five present
  in the bundle; `plutil -extract UIAppFonts` on the built `Info.plist` → all five
  registered.
- Ran on the simulator (iPhone 16, iOS 26.1 — note the project's deployment target is
  iOS 26, so the default "iPhone 16 / iOS 18.5" device refuses to install) and
  screenshotted all four screens. Instrument Serif and Sans render; the palette is
  cream; the primary button is an ink pill; the genre chips fall and are ink-outlined
  with no icons and no colour.
- Relaunched with `-AppleLanguages '(pt-BR)'` and confirmed the flow reads in
  Portuguese with no raw keys and correct accents.
- Every one of the 18 new keys has both `en` and `pt-BR`. (26 of the 235 total keys
  lack one or both — all pre-existing format-placeholder and literal-string keys, not
  introduced here.)
- `GenrePhysicsScene.swift` confirmed unmodified in `git status`.

The three screens beyond Welcome were reached with a temporary `ScreenshotHarness` in
`RootView`, because the simulator was driven headless and neither `idb` nor
AppleScript-driven tapping was available. It was reverted from the backup before
committing; `git diff ReadUp/App/RootView.swift` is empty.

## Open items

- **The other 17 screens.** Home, Library, Book details, Add a book, Scanner, Reading
  session, Session summary, History, Profile now render in the new palette and type
  without their code changing, but their *layouts* are still the old ones. They need a
  visual pass for contrast regressions — anything that assumed a green `brand` or a
  dark-mode flip. Not done here.
- **`ForgotPasswordView` and `ResetPasswordView`** are not in this cycle's Figma frames
  and still use the boxed `AuthTextField`. They will look inconsistent next to the
  restyled Sign in screen. Migrating them to `UnderlinedField` is the obvious next
  small task.
- **`AuthComponents.swift` is now legacy.** `AuthTextField` / `AuthSecureField` /
  `AuthPrimaryButton` survive only because Forgot/Reset password still use them.
  Delete the file when those two screens migrate.
- **`cardShadow()` call sites.** One remains. It is a no-op, so it is harmless, but the
  deprecation warning will point at it.
- **`WarningBanner` (`37:290`) and `StatusControl` (`37:282`)** are specified on the
  Design System page and not built. They belong to the screens above.
- **Genre chips remain bitmaps** inside a `SpriteView` — no VoiceOver labels, no
  Dynamic Type. Marked with a `ponytail:` comment in `GenreOnboardingView.chipView`.
  The upgrade path is a `Layout`-based flow grid of real SwiftUI chips, which is what
  the Figma frame actually shows; that trade was made deliberately to keep the physics.
- **`SessionSummaryShareCard`** renders to an image for sharing and was not re-rendered
  this cycle. Worth one check that the cream background exports correctly.
