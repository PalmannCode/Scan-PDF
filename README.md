# Scan PDF: Genius Expert Editor

Production Flutter source for VictoryASO Jira parent `SUBAPPS-122` and
Development ticket `SUBAPPS-129`, including the MVP, V2, AI, Supabase,
Receipt Rescue, and icon requirements. The separate Web2App checkout is
deferred and is not part of the current native-app release scope.

The product is local-first: guests can scan, edit, organize, search, and export
without an account or network connection. Signing in with Apple or a
passwordless email link enables optional Supabase backup, cross-install restore,
server-validated entitlement state, AI tools, priority support, expense reports,
and saved automation settings.

## Release identity

| Item | Value |
| --- | --- |
| Flutter version | `1.0.0+1` |
| Bundle ID | `com.futurafund.scanpdf` |
| App Store ID | `6792221523` |
| Minimum iOS | 15.5 |
| Subscription product | `plus_pdf_monthly` |
| Subscription offer | 3-day trial, then $3.99/month |
| Event link | `scanpdf://receipt-rescue` |
| Event window | 2026-08-17 through 2026-09-17 23:59 |
| Event goal | 15 receipts |

StoreKit supplies the localized live price. `$3.99/month` is fallback display
copy and must match App Store Connect before submission.

## Implemented product surface

- Document, Text, Book, QR, Translate, Measure, and Count camera modes
- Apple Vision document detection, perspective correction, auto-capture, OCR,
  and QR decoding; page split and cleanup for book spreads
- Batch review, crop, rotate, filters, add/reorder/delete pages, folders, trash,
  OCR search, and local offline storage
- PDF/JPG/PNG/TXT/Word/PowerPoint export, AirPrint, searchable PDFs,
  compression, extraction, text/image watermarks, and PDF password protection
- Drawn, imported, reusable, default, and cloud-backed signatures
- Apple and passwordless-email authentication through Supabase PKCE
- Optional cloud backup/restore, auto upload, settings/workflow/signature sync,
  RLS-protected metadata, and private Storage buckets
- Ask AI, summaries, structured extraction, translation, object count, and
  editable PDF/CSV expense reports through authenticated Edge Functions
- Direct App Store IAP through StoreKit and App Store Connect; Stripe is not a
  dependency of the native application
- Priority support, workflow templates, alternate app icons, Amplitude events,
  Receipt Rescue, Game Center capability, and Codemagic iOS release automation

## Local setup

Prerequisites: Flutter, Xcode, CocoaPods, and Deno. A physical iPhone is required
for final camera, StoreKit, Sign in with Apple, alternate-icon, and share/print
acceptance tests.

```sh
flutter pub get
dart run build_runner build
cd ios && pod install && cd ..
```

Supply public client configuration with Dart defines:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=AMPLITUDE_API_KEY=...
```

The same variables belong in Codemagic group `scanpdf_public_config`. They are
public client identifiers, not administrative secrets. Copy `.env.example` for
the full server-secret checklist. Never put a Supabase service-role key,
OpenAI key or App Store private key in Flutter, Git, or chat.

## Supabase

The schema, RLS policies, private buckets, and auth-profile trigger live in:

```text
supabase/migrations/202608170001_scan_pdf_schema.sql
```

The two migrations are already applied to project
`iyxksejttlhtcqwhpuvl`. Deploy the functions with the Supabase CLI after the
CLI identity has project-management access, then set server-only secrets in
Supabase's secret store. Required functions are:

- `ai_document_assistant`
- `translate_document`
- `validate_entitlement`
- `delete_account`

For Apple authentication, enable the Apple provider in Supabase and allow
`scanpdf://auth-callback`. The live project currently has email enabled and
Apple disabled; the local CLI identity receives a 403 from the project's
management endpoints, so this requires Developer/Owner project access. Email
magic links use the same callback. Keep the native bundle identifier aligned
with the Apple service configuration.

## CI

The existing `web2app/` prototype and its Stripe Edge Functions are parked for
a later phase. They do not need to be deployed or configured for this native
release. Native purchases use the App Store product `plus_pdf_monthly`.

`codemagic.yaml` contains one `ios-release` workflow. Configure:

- Codemagic App Store Connect integration group `appstore_credentials`
- public group `scanpdf_public_config`
- an App Store distribution certificate and provisioning profile for
  `com.futurafund.scanpdf`

The non-secret App Store Connect issuer ID and key ID from Jira Setup are
already present in `codemagic.yaml`. Add only the contents of Jira attachment
`AuthKey_849GKT37AM.p8` as the encrypted
`APP_STORE_CONNECT_PRIVATE_KEY` value in Codemagic. The separate
`AuthKey_DP3Q5WL46F.p8` file is for APNs and must not be used for App Store
Connect publishing or StoreKit validation.

The workflow resolves packages, installs Pods, generates source, analyzes,
tests, builds a signed IPA with the next App Store build number, and uploads it
to App Store Connect without automatically submitting it for review.

## Verification

Local gates:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
deno check supabase/functions/*/index.ts
plutil -lint ios/Runner/Info.plist ios/Runner/Runner.entitlements
flutter build ios --simulator --debug
flutter build ios --release --no-codesign
```

These establish local code/build readiness, not deployed-service or App Store
proof. Before submission, complete the live checklist in
`JIRA_IMPLEMENTATION_AUDIT.md`, especially Supabase auth/RLS, AI consent,
App Store Server validation, StoreKit sandbox purchase and restore, Amplitude
receipt, event publishing, Game Center/App Store capability state, and a signed
TestFlight install.
