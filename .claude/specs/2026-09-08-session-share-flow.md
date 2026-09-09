# Session share flow

**Status:** approved 2026-09-08 · Figma `Session share flow` section, page `Screens`,
file `47zjMbONNMeZJ4WFmEe8MC`.

## Problem

Sharing a reading session to Instagram today is a clipboard errand. `SessionSummary`
renders `SessionSummaryShareCard` to a transparent PNG, copies it to
`UIPasteboard.general.image`, opens `instagram://story-camera`, and shows a toast
telling the user to paste it. The alternative is saving the PNG to the photo library
through the system share sheet and finding it again inside Instagram.

Both paths make the user do the app's job. Neither is discoverable: the only hint is a
caption under the button reading "the card is copied to your clipboard — paste it in
your story."

Two further problems surfaced while designing the replacement:

1. **The card was below WCAG AA before any photo was involved.** Measured against
   `surface/raised` (`#FDFBF7`), the 11px overlines at `ink/meta` came out at 3.6:1,
   `Made with ReadUp` at `ink/faint` at 2.9:1, and the 18px author line at `ink/soft`
   at exactly 4.5:1. AA wants 4.5:1 for anything under 18.66px bold / 24px regular.
2. **Legibility over a photo cannot depend on the photo.** The first design laid cream
   type directly on the camera feed. On a bright shot that is unreadable, and no amount
   of scrim tuning fixes the general case without burying the photo.

## Decision

A five-screen flow, all built from Editorial Cream tokens, replacing the clipboard
hand-off entirely.

```
10 · Session summary  ──Share──▶  10b · Share (carousel)
                                    │
                        ┌───────────┴───────────┐
                   Your photo              Just the card
                        │                       │
                 10c · Camera                   │
                        │                       │
                 10d · Edit  ──────────▶  10e · Card ready
                                                │
                                   Share to Stories │ Share… (native)
```

### The card is one component with two skins

`Story card / Session` in Figma; `SessionSummaryShareCard` in code. Layout is
identical between skins — only the ground and the ink change:

- **Solid** — `surface/raised`, opaque, edge to edge. The standalone story, exported
  1080×1920. Contrast is fixed and measured: 6.7:1 on the 11px overlines, 5.4:1 on the
  author and footer, 17.5:1 on the titles.
- **Sticker** — **no ground at all**, cream type carrying a drop shadow, laid over the
  user's photo and freely dragged, pinched and rotated.

**On the sticker skin there is no ratio to guarantee, and that is a deliberate
trade.** Without a panel the ground is the user's photo, and no type colour clears
4.5:1 against every possible photo. Two panels were built and rejected because both
destroyed the thing the feature exists for:

- a dark scrim needed ≥0.75 alpha to clear 4.5:1 against a white shot, at which point
  the photo is gone;
- a frosted cream panel at 0.82 measured 10.9:1 but was effectively opaque, so the
  photo was gone as well.

An opaque, shrunken card was tried third and also rejected: it measured perfectly but
read as a cream block sitting on the picture.

The mitigation is a drop shadow on every text run — the same technique Instagram and
iOS use for captions over photos. It resolves real-world legibility across the
overwhelming majority of scenes without covering the photo. The book cover keeps its
own ink type, because the cover is an opaque light surface of its own rather than part
of the photo.

The card is signed by the reader: avatar and display name above the `Made with
ReadUp` line, which carries the app mark beside it.

### Contrast ramp, corrected

Applied to both skins, so the exported card and the overlaid one are the same:

| Element | Was | Now | Ratio on cream |
|---|---|---|---|
| `READING SESSION`, `PAGES`/`TIME`/`DONE` (11px) | `ink/meta` | `ink/strong-muted` | 6.7:1 |
| Author (18px italic serif) | `ink/soft` | `ink/muted` | 5.4:1 |
| `Made with ReadUp` (12px) | `ink/faint` | `ink/muted` | 5.4:1 |

### Chrome over the photo is ink-backed, not cream-backed

Every control on `10c` and `10d` — close, flip, tool rail, segmented control, hint —
sits on `ink` at 72% with a cream hairline and a soft shadow, carrying cream glyphs.
That is 6.5:1 for the glyph even when the photo behind is white. Cream-on-cream chips
were the first attempt and vanish on a bright shot. The shutter keeps its cream ring
but gains a dark edge for the same reason.

### The editor is native frameworks only

Drag / pinch / rotate on the card is `DragGesture` + `MagnifyGesture` +
`RotateGesture`. Text is a `TextField` overlay — the emoji keyboard comes free with
it, so there is no emoji picker to build. Drawing is `PKCanvasView` (PencilKit), which
ships the tool picker, colours, widths and undo. No new dependency, and no hand-rolled
layer stack.

Deliberately **not** built: filters, stickers beyond emoji, per-layer z-ordering, a
custom colour picker. PencilKit and the keyboard already cover what the flow needs.

### Two destinations, no clipboard, no photo library

- **Share to Stories** — `instagram-stories://share` with
  `com.instagram.sharedSticker.backgroundImage` set to the composed PNG. Instagram
  opens with the image already in place. `LSApplicationQueriesSchemes` already
  declares the scheme.
- **Share…** — `UIActivityViewController` on the same PNG.

Instagram not installed falls back to the native sheet.

## Rejected

**Instagram's sticker hand-off** (`com.instagram.sharedSticker.stickerImage`, which
drops the card into Instagram's own editor as a movable sticker) would have removed
the camera and editor screens entirely and come with Instagram's text, emoji, draw,
music and Close Friends for free. It was offered and declined: the flow should stay
inside ReadUp so the app owns the composition, and so the non-Instagram path is not a
second-class citizen.

## Consequences

- `Info.plist` needs `NSCameraUsageDescription`. It has none today — the ISBN scanner
  reaches the camera through VisionKit but the key was never added, so this flow would
  crash on first capture without it.
- `Localization+SessionSummary` loses `shareToInstagram`, `clipboardInstruction` and
  `clipboardCopied`, and gains the flow's own strings.
- The `10 · Session summary` artboard in Figma is superseded by the one in the
  `Session share flow` section.
