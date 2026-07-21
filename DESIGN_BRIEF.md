# DESIGN BRIEF — Scan PDF: Genius Expert Editor

Derived from Jira SUBAPPS-122 / SUBAPPS-129 (Development spec §5 Design Direction).
Every visual and motion decision in this app defers to this document.

## App identity

- **Niche**: scan-first PDF scanner + professional document editor (daylight productivity utility)
- **Audience**: professionals, students, everyday admin — people digitizing paper fast
- **Mood (from Jira)**: minimal · premium · scan-first · fast · professional · simple outside, powerful inside Tools
- **Core promise**: "Scan anything. Edit professionally. Export anywhere."

## 1. Archetype — Swiss / Precision Utility (customized: "Dark Scanner Shell")

Base archetype #5 (Swiss/Precision Utility): strict grid, ordered density, functional
color coding, flat surfaces, mechanical motion. Customized for this app's Jira design:
a **dual-surface system** —

- **Dark indigo shell** for the scan hub (My Scans home, camera, event): deep indigo
  background, white text/icons, elevated surfaces are *lighter indigo fills* (no glow,
  no glass, no mesh — this is NOT Luminous Dark).
- **Paper surfaces** for content work (tools sheet, settings, viewer, save flow):
  white/soft-grey sheets slide over the dark shell as large rounded bottom sheets or
  pushed light screens, navy text, hairline rules.

The contrast dark-hub / light-paper IS the identity: the app "shell" is the scanner
hardware, the light sheets are the paper you work on.

## 2. Typography — Archivo Expanded + Archivo, IBM Plex Mono for numerals

- **Display**: Archivo (SemiBold/Bold, expanded feel via weight + tight tracking) —
  headlines, screen titles, onboarding. Archivo is a grotesque designed for print —
  right for a document app.
- **Body/UI**: Archivo (Regular/Medium) — labels, rows, buttons.
- **Numerals & metadata**: IBM Plex Mono — page counts, file sizes, dates, timers,
  the event counter. Tabular, typewriter-adjacent = document DNA. Numbers ALWAYS
  render in Plex Mono; this is a hard rule (Swiss "monospace for all numbers").
- Never Poppins/Inter-for-everything.

## 3. Shape language

- **Radius scale**: chrome pills (search bar, floating action bar, chips) = 999 (full
  pill); bottom sheets = 28 top corners; cards/tiles = 14; thumbnails = 10; buttons = 14.
- **Borders**: light surfaces use 1px hairline `#E4E4EE` rules and dividers (native-style
  settings rows); dark surfaces use fill-elevation only (no borders).
- **Shadows**: `none` on dark shell (elevation = lighter fill); `soft` on light sheets
  (y=8, blur=24, black 6–8%) — never hard offsets, never glow.
- Document thumbnails always carry a subtle "sheet edge": 1px hairline + tiny folded-corner
  motif from the signature language.

## 4. Color strategy — dark-first shell, paper content, one working accent

From Jira's named palette (hexes committed here):

| Token | Hex | Role |
|---|---|---|
| `deepIndigo` | `#26214F` | shell background (home, camera, event) |
| `indigoDeeper` | `#1C1840` | shell gradient foot / splash dark |
| `indigoElevated` | `#38316B` | search bar, cards, chips on dark |
| `scanOrange` | `#FF7A2E` | THE accent: scan button, primary CTAs, Plus badge, progress |
| `scanOrangeDeep` | `#F2600F` | pressed/gradient partner of accent |
| `paperWhite` | `#FFFFFF` | sheets, light screens |
| `softGrey` | `#F4F5F9` | tool cards, light screen background |
| `navyText` | `#1C1B3A` | primary text on light |
| `mutedLavender` | `#A9A5CE` | secondary text on dark |
| `mutedSlate` | `#6E6D8A` | secondary text on light |
| `successGreen` | `#2FB47C` | success/OCR-done (functional coding) |
| `dangerRed` | `#E5484D` | destructive/trash (functional coding) |

- Accent is **reserved**: scan/primary action, Plus marking, active progress. Never for
  decoration washes.
- **Light theme** (default): as above. **Dark theme**: shell unchanged; paper surfaces
  swap to dark navy (`#211D48` sheets on `#17143A` bg, text `#F2F1FA`) — the indigo
  shell is constant in both, which keeps the brand identity stable.
- Splash: `deepIndigo` (dark-first shell app) / dark variant `#1C1840`.

## 5. Navigation pattern

Single-hub, sheet-and-push (exactly the Jira structure, no tab bar):

- **My Scans** is the only root screen. Top-left gear → Settings (push, light). Top-right
  ⋯ → anchored popover menu. Search bar → search screen (push, dark).
- **ScanDock** floating pill bar (bottom): Tools (sheet) · big orange Camera button (push,
  full-screen dark) · Photos (system picker).
- Tools = large rounded bottom sheet over the home. Viewer/save/review = pushes.
- Event screen: push from home banner + `scanpdf://receipt-rescue` deep link.
- go_router; transitions per motion personality below.

## 6. Motion personality — mechanical, fast, precise

- **Durations**: micro 120ms · standard 180ms · sheets/pages 240ms. Curves:
  `easeOutCubic` (enter), `easeInCubic` (exit). NO springs, NO overshoot, NO bounce
  (Jira: "no heavy animations").
- **Page transitions**: fade-through (`animations` pkg) for pushes; sheets slide up 240ms.
- **Press feedback**: `dim` style (opacity 0.62, instant in, 120ms release) on dark shell
  chrome; `scale` 0.97/100ms on light-surface cards and CTAs. Always light haptic.
- **Lists**: stagger 40ms/item, fade + 6px rise, mechanical (no scale).
- **Living details** (exactly two ambient motions): (1) the ScanPulseFrame beam sweep on
  the home empty state / scan CTA; (2) Plex-Mono count-up ticks on stats (library counts,
  event rescue counter). Both inside RepaintBoundary.
- Success moments (scan saved, OCR done): 240ms check-draw + heavy haptic, no confetti.

## 7. Signature component — **ScanPulseFrame**

`CustomPainter` widget, named for the domain, nowhere from a package:

- Four orange corner brackets (the universal "scan frame" glyph) drawn with rounded caps
  around a slot; a soft-edged **scan beam** sweeps top→bottom on a slow loop (2.8s,
  easeInOutSine) with a faint trailing gradient; optional tick marks on the left rail
  (Swiss precision ruler motif).
- **Home**: hero of the empty state (framing a custom-painted paper sheet illustration)
  and, once documents exist, a compact header variant frames the library stats strip.
- **Camera**: the same frame is the capture overlay (still variant + "scanning" sweep on
  capture) — one visual system across the app.
- **Event**: frames the FadingReceipt painter on the Receipt Rescue screen.
- Motif echoes: corner-bracket fragments as decoration in AppBackground (barely-visible
  oversized brackets, 3–4% white on the dark shell), folded-corner on thumbnails,
  bracket bullets in onboarding.

## Background treatment (AppBackground)

- **Dark shell**: flat `deepIndigo` with a very subtle vertical deepening toward
  `indigoDeeper` + the oversized bracket motif at 3–4% opacity (CustomPainter). Static.
- **Light screens**: flat `softGrey` / `paperWhite`. No texture, no mesh, no vignette.

## Onboarding structure (anti-template rule #1)

Jira explicitly mandates: 3 screens, swipe, skip, no heavy animation, exact copy (§6).
Honored — but NOT the generic centered-icon template: each screen is a full-bleed
**custom-painted scene** in the app's shape language:

1. "Scan documents in seconds" — ScanPulseFrame over a paper sheet, beam mid-sweep.
2. "Edit like an expert" — painted page with crop handles + signature stroke drawing in.
3. "Export anywhere" — painted sheet fanning into PDF/JPG/TXT/DOCX file chips.

Progress: 3 Swiss tick-dashes (not dots) + Skip top-right; CTA pill in scanOrange.
Footer: implicit consent line with Privacy/Terms links.

## Empty states / error views

Custom-painted from the shape language ONLY (no packages, no Lottie — none shipped):
- Library empty: ScanPulseFrame + muted paper sheet, "No scans yet".
- Search empty/no-results, trash empty, folder empty: paper-sheet variants w/ bracket motif.
- Error view: sheet with a torn edge + retry CTA.

## Do-not list (from Jira "Avoid" + archetype)

No mesh gradients, no glass/blur panels, no glow shadows, no springs/bounce, no confetti,
no cluttered dashboards, no multi-tab navigation, no heavy banners, no circular spinners
(shimmer only), no Poppins/Inter-default typography.
