# Jira implementation and release audit

Source of truth re-read live on 2026-08-17:

- Parent `SUBAPPS-122`
- Development `SUBAPPS-129`, complete description
- All six Development comments: `52833`, `52899`, `52933`, `53675`, `54249`,
  and `54250`
- Related setup/distribution/push-funnel tickets `SUBAPPS-128`, `SUBAPPS-130`,
  and `SUBAPPS-155`

The implementation follows the user's later decisions where they supersede the
ticket's recommended defaults: Game Center remains enabled, Receipt Rescue
remains in the app, bundle ID is `com.futurafund.scanpdf`, App Store ID is
`6792221523`, and Plus uses `plus_pdf_monthly` at $3.99/month with a 3-day
introductory trial. Guest use remains local-first; account, cloud, and AI are
optional.

## Status definitions

- `LOCAL VERIFIED`: implemented and covered by the current analyzer, automated
  tests, backend type checks, or iOS build.
- `CODE READY`: implemented but the final behavior depends on camera/content,
  OS UI, or a configured external service.
- `LIVE GATE`: requires credentials, provider state, deployment, App Store
  Connect, or a physical-device receipt; local code cannot prove it.
- `LIVE VERIFIED`: confirmed directly against the configured external service.

## Complete requirement matrix

| Jira area | Status | Implementation / acceptance boundary |
| --- | --- | --- |
| Dark My Scans shell, floating actions, menus | LOCAL VERIFIED | Search, grid/list, sort, folders, trash, import, and persisted view state |
| Onboarding | LOCAL VERIFIED | Three swipe screens, skip/CTA, specified copy, analytics |
| Camera Document/Text | CODE READY | Manual/batch capture, Apple Vision edges, two-frame auto-capture, crop, perspective correction, filters, OCR; physical camera quality still required |
| Book Scan | CODE READY | Spread split, gutter trim, cleanup filter, batch/reorder/PDF; curved-binding and shadow quality need real-book field QA |
| QR Code | CODE READY | On-device Apple Vision decode, URL open, copy, share; physical camera proof required |
| Translate | CODE READY | On-device OCR, language target, explicit-consent backend translation, original/translated display, copy/share |
| Measure | CODE READY | Calibrated reference/target overlay, cm/inch, manual adjustment, result image save/share |
| Count Objects | CODE READY | Explicit-consent vision request, count/label/confidence/notes, manual count correction, image/result save/share |
| Page review | LOCAL VERIFIED | Crop, rotate, retake/add, delete, drag reorder, six filters, batch save |
| Viewer/page management | LOCAL VERIFIED | Zoom/swipe, rename, move, add/reorder/delete/extract/duplicate pages |
| Folders and Trash | LOCAL VERIFIED | Create, rename, delete/detach, move, search, restore, permanent delete, empty Trash |
| OCR and search | CODE READY | Apple Vision OCR, language bundles, automatic OCR, per-page editable text, OCR-backed search/TXT/Word, optional searchable PDF text layer |
| Core export | LOCAL VERIFIED | PDF, JPG, PNG, TXT, Word OOXML, PowerPoint OOXML, system share, AirPrint |
| Advanced PDF tools | CODE READY | Low/medium/high compression, text/image watermark with opacity/position/repeat/page range, PDFKit password protection |
| Signatures | CODE READY | Draw/import, transparent placement, resize, selected/all pages, reusable named/default library, optional cloud sync |
| Merge | LOCAL VERIFIED | Independent page-file copies prevent source deletion from breaking merged output |
| Expense Report | CODE READY | Multi-receipt OCR + strict AI extraction, editable merchant/date/total/tax/currency, PDF/CSV export |
| Fax | REMOVED | Removed from the application, routes, paywall, backend schema/functions, metadata, and release scope by owner decision on 2026-08-17 |
| Apple/email auth | LIVE GATE | Native nonce-based Apple flow, PKCE, magic links, sign-out, deletion. Live Auth settings report email enabled and Apple disabled; the callback config cannot be pushed by the currently authenticated Supabase CLI account (403 insufficient privileges) |
| Supabase schema/RLS/Storage | LIVE VERIFIED | Both migrations are recorded in project `iyxksejttlhtcqwhpuvl`; all 13 app tables have RLS enabled, all seven storage buckets are private, and no fax table remains |
| Cloud backup and Auto Upload | LIVE GATE | Local-authoritative upload, remote restore, settings/signature/workflow sync; requires deployed project and two-install test |
| AI assistant | LIVE GATE | Ask, summary, key points/actions, strict structured extraction, translation, classification fields, object count, usage limits. The supplied key completed a direct `gpt-5.6` Responses smoke request, but functions and the Supabase secret are not deployed because project-management access is missing |
| AI privacy | CODE READY | Consent precedes document text or image processing; OpenAI secret is server-only, requests use `store: false`, and a hashed per-user `safety_identifier` is sent |
| Plus IAP | LIVE GATE | Direct StoreKit purchase/restore, signed-in App Store Server validation, Supabase entitlement refresh; requires ASC product/offer and Sandbox/TestFlight proof |
| Stripe Web2App | DEFERRED | Explicitly removed from the current native-app release scope on 2026-08-17. Its prototype remains parked but is not deployed, configured, or required by StoreKit IAP. |
| Workflows | CODE READY | Persisted Scan→OCR→Upload, Scan→Sign→Email, Image→PDF, Receipt→Expense templates with optional Supabase metadata |
| Priority Support | LIVE GATE | Plus/signed-in Supabase ticket creation and public support fallback; requires deployed table and delivery/operations proof |
| Settings | LOCAL VERIFIED | Scan/OCR/searchable PDF, quality, theme, filename, email template, diagnostics, icons, workflows, signatures, account/sync, subscription, support/legal |
| Alternate icons | CODE READY | Default, dark, orange camera, minimal, Plus iOS app icon sets and runtime switch; physical iPhone proof required |
| Updated launcher/splash icon | LOCAL VERIFIED | Regenerated iOS, Android, web, and splash assets from current `assets/icon.png`; iOS 1024 icon is opaque |
| Receipt Rescue | LOCAL VERIFIED | Deep link, upcoming/live/ended logic, home banner, local once-per-document progress, 15 goal, automated tests; ASC event publication is live gate |
| Game Center | LIVE GATE | Entitlement is in the binary; App Store Connect capability state must be confirmed |
| Amplitude | LIVE GATE | Scan PDF project API key is configured; centralized snake_case lifecycle/product/tool/auth/purchase events and identity still require live event receipt proof |
| Account deletion | LIVE GATE | Edge Function removes all seven bucket trees then the auth user; deployed end-to-end deletion test required |
| Codemagic | CODE READY | Single signed iOS workflow: packages, Pods, codegen, analyze, tests, IPA, next build number, ASC upload |
| GitHub remote | LIVE VERIFIED | `origin` is configured as `PalmannCode/Scan-PDF` on branch `master` |
| Local metadata protection | LOCAL VERIFIED | Hive document, folder, and preference boxes use AES encryption with a Keychain/Keystore-held random key and preserve plaintext boxes during one-time migration |
| Push notifications / funnel routing | NEEDS SPEC | `SUBAPPS-155` has only a title; its description, comments, and attachments are empty. No push/funnel SDK was invented or added without a provider/domain contract |
| App Store metadata/privacy | LIVE GATE | Metadata is reconciled; reviewer identity, legal company, final privacy questionnaire, event/product state, and screenshots remain account-owner inputs |
| Hosted legal text | LIVE GATE | Current Privacy Policy is generic and does not specifically disclose account email, scanned/OCR/AI content, Supabase, OpenAI, or Amplitude; current Terms do not state the monthly auto-renewal/trial terms. Account owner/legal review must update both hosted documents before submission |
| Free-tier quantities | PRODUCT DECISION | Jira specifies a soft freemium model and an AI cap but does not give numeric OCR, advanced-conversion, or folder allowances. AI is currently limited to 3 messages/month; Plus-only workflows and reusable signatures are enforced. Exact OCR, conversion, and folder limits need owner approval before those counters can be enforced without inventing product policy. |

## Local evidence

The final acceptance run must retain these outcomes:

- Dart format: no changes
- Flutter analyzer: no issues
- Flutter tests: all tests pass, including repository rollback/deletion,
  scanner/crop invariants, event/deep-link/release constants, signatures,
  alternate-icon mapping, watermark PDF creation, and valid Word/PowerPoint ZIP
  structure
- Deno: all Edge Function entry points type-check
- Deno: all Edge Function sources pass `deno fmt --check`
- CocoaPods: clean install with no base-configuration warning
- Plists: Info and entitlements parse
- iOS arm64 simulator debug build: succeeds
- iOS device release build without signing: succeeds

These are local readiness only. They are not evidence of App Store upload,
StoreKit renewal/restore, Apple auth, Supabase RLS, OpenAI output, analytics
receipt, event publication, or a signed physical-device install.

## Live state and remaining inputs

Public build configuration is complete in Flutter defaults and Codemagic:

- `SUPABASE_URL=https://iyxksejttlhtcqwhpuvl.supabase.co`
- Supabase legacy public anon key
- Scan PDF Amplitude project API key; the legacy Amplitude key is intentionally
  not used

Supabase database configuration is live:

- Migrations `202608170001` and `202608170002` are applied and recorded
- 13 public app tables have RLS enabled
- Seven private storage buckets exist

Supabase management access is still required:

- Enable the Apple provider for the app's Apple identity; the live provider is
  currently disabled
- `scanpdf://auth-callback` is declared in `supabase/config.toml`; push it to
  the remote Auth URL configuration
- Deploy the four native-app Edge Functions. The deferred Stripe checkout
  functions are not required
- The current CLI identity can reach other Supabase projects but receives a
  403 for this project's management endpoints. Add this account to the project
  with Developer/Owner access or provide a Supabase personal access token with
  permission for project `iyxksejttlhtcqwhpuvl`.

Server-only secrets—set in Supabase/Codemagic secret stores, never Flutter or
Git:

- `OPENAI_API_KEY`; the exact supplied key is valid, but cannot be written to
  Supabase until project-management access is available
- `OPENAI_MODEL=gpt-5.6`
- `APP_STORE_ISSUER_ID=5e597735-8463-4139-84fa-bb390c06bbf7`
- `APP_STORE_KEY_ID=849GKT37AM`
- `APP_STORE_PRIVATE_KEY`: contents of Jira Setup attachment
  `AuthKey_849GKT37AM.p8`. The Jira connector exposes the attachment metadata
  but not its file contents, so the `.p8` must be downloaded/provided through a
  secure channel.
- `APP_STORE_BUNDLE_ID=com.futurafund.scanpdf`
- `APP_STORE_PRODUCT_ID=plus_pdf_monthly`

Codemagic/App Store inputs:

- App Store Connect private-key secret, distribution certificate, and profile;
  the Jira issuer/key identifiers are already wired into `codemagic.yaml`
- App Store reviewer first/last name, email, phone, and legal company name
- Final App Privacy answers for account email, user documents/photos/OCR text,
  purchases, user ID, support content, product interaction/analytics, and AI
  processing disclosures
- Update the hosted Privacy Policy and Terms so their actual disclosures match
  the implemented cloud, AI, analytics, App Store payment, deletion, retention,
  and
  3-day-trial/$3.99-monthly subscription behavior
- Confirm monthly product, 3-day trial, Receipt Rescue event, and Game Center
  capability in App Store Connect
- Physical iPhone + Sandbox/TestFlight account for the live acceptance matrix

Subscription source conflict:

- The owner's explicit approved native product is `plus_pdf_monthly` at
  $3.99/month with a 3-day trial, and the app intentionally preserves it.
- Jira comment `54250` instead lists `scanpdf.plus.weekly` at $3.99 and
  `scanpdf.plus.monthly` at $9.99. App Store Connect must be created/updated to
  match the owner's approved product before StoreKit testing.

Push/funnel input still required:

- `SUBAPPS-155` provides no implementation contract. Supply the intended push
  provider/SDK, project configuration, and funnel-routing endpoint/behavior if
  this separate feature is still required for the native release.

Product decision still required:

- Approve or replace the proposed free allowances: 10 OCR pages/month, 3
  advanced conversions/month, and 3 folders. AI remains 3 messages/month;
  workflows and reusable signatures remain Plus-only. Until approved, the app
  does not block the otherwise local core OCR/export/folder flows using
  arbitrary limits that Jira did not define.
