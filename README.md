# Scan PDF: Genius Expert Editor

Production Flutter source for the local-first iPhone scanner specified in the
VictoryASO Jira project (`SUBAPPS-122`, development ticket `SUBAPPS-129`). The
app captures and imports pages, corrects perspective, applies scan filters,
runs on-device text recognition, organizes documents, signs and merges pages,
and exports PDF, image, text, and print output.

## Product boundaries

- Documents, page images, folders, OCR text, event progress, preferences, and
  Plus entitlement state are stored on the device.
- Version 1 has no account, authentication, analytics SDK, cloud sync,
  Supabase, or document backend.
- Network access is limited to user-initiated App Store purchase and restore
  actions and external support, legal, review, and subscription-management
  links.
- OCR uses Apple's Vision framework through the iOS platform channel.
- The iOS target is iPhone-only and portrait-only.

## Release configuration

| Item | Value |
| --- | --- |
| Version | `1.0.0+1` |
| Bundle ID | `com.futurafund.scanpdf` |
| App Store ID | `6792221523` |
| Minimum iOS | 15.5 |
| Subscription | `plus_pdf_monthly` |
| Subscription offer | 3-day introductory trial, then $3.99/month |
| Game Center | Entitlement enabled; no v1 leaderboards or achievements |
| Event deep link | `scanpdf://receipt-rescue` |
| Event window | 2026-08-17 through 2026-09-17 23:59 |
| Event goal | 15 receipts |

The StoreKit product, its monthly duration, $3.99 price, and 3-day introductory
offer must match this table in App Store Connect before release. The app reads
the localized live price from StoreKit and uses `$3.99` only as fallback copy.

## Local development

Prerequisites:

- Flutter and Dart versions compatible with `pubspec.yaml`
- Xcode with an iOS 15.5 or newer SDK
- CocoaPods
- A physical iPhone for camera and StoreKit sandbox validation

Install and generate code:

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cd ios
pod install
cd ..
```

Run local checks:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build ios --release --no-codesign
```

The repository ignores build output at every directory depth. Generated Xcode
DerivedData and Flutter build products must not be committed.

## Architecture and storage

The app uses feature-first Flutter code with Riverpod state management and
GoRouter navigation:

- `lib/features/scanner`: camera, crop, review, filters, and atomic save flow
- `lib/features/home`: local document/folder repositories and library UI
- `lib/features/viewer`: export, OCR text, signing, merging, and page actions
- `lib/features/paywall`: direct App Store subscription and restore flow
- `lib/features/event`: Receipt Rescue deep link, window, and local progress
- `lib/features/settings`: scanning preferences, support, legal, and subscription
- `lib/services`: image processing, PDF, OCR bridge, purchases, and exports

Hive stores metadata; processed and original page images live in the app's
documents directory. A failed multi-page save rolls back files created during
that attempt. A damaged Hive entry is skipped so one malformed record cannot
prevent the rest of the library from opening.

The Archivo and IBM Plex Mono font files are bundled under `assets/fonts`, so
the design typography does not require a runtime font download. Their OFL
license files are bundled and registered with Flutter's license registry.

## App Store assets and metadata

- `asc_metadata.json`: en-US App Store metadata and review notes
- `DESIGN_BRIEF.md`: approved visual system and product behavior
- `localized-screenshots/en-US/`: generated 1320×2868 simulator screenshots
  (ignored by Git because release tooling owns screenshot upload)
- `assets/icon.png`: launcher and splash source art

The Jira signing-key and Firebase attachments are private release inputs and are
not stored in this repository. Do not commit `.p8` keys, API keys, provisioning
profiles, or App Store Connect credentials.

Before metadata submission, fill the reviewer first name, last name, phone, and
email plus the legal company name/copyright in `asc_metadata.json`. The current
`null` contact fields are intentionally left as a release gate rather than
inventing identity data.

## Physical-device acceptance checklist

- Deny camera access, verify the recovery screen, grant access in Settings, and
  retry successfully.
- Capture single and batch scans; crop, rotate, filter, reorder, add, and remove
  pages; interrupt one save and confirm no partial document remains.
- Import photos, images, and a multi-page PDF from Files.
- Confirm Vision OCR text appears in search and TXT export while offline.
- Draw a signature, verify transparent placement, pinch/drag it, and confirm the
  saved page does not receive an opaque signature background.
- Export PDF, JPG, PNG, and TXT; share and print to an available AirPrint target.
- Move documents to Trash, restore them, delete permanently, and empty Trash.
- Open `scanpdf://receipt-rescue`, verify the event screen, and confirm eligible
  live-window scans count only once toward the 15-receipt goal.
- With a Sandbox Apple ID, load `plus_pdf_monthly`, start the 3-day trial at the
  localized $3.99/month renewal price, cancel, restore, and verify both Restore
  Purchases entry points.
- Confirm App Store Connect has Game Center enabled for version 1.0.0 and that
  the binary includes the Game Center entitlement.
- Install with networking disabled and verify the bundled typography renders on
  onboarding, home, scanner, viewer, settings, paywall, and event screens.

Passing analyzer, unit tests, and a no-codesign release build establishes local
readiness only. StoreKit sandbox behavior, camera quality, OCR results, print and
share destinations, Game Center/App Store Connect state, and event publishing
still require account-backed or physical-device verification.
