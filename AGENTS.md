# AGENTS.md

TravelBuddy: a social travel planning Flutter app (UPLB CMSC 23 project) where users create, share, and co-edit trip itineraries.

## Stack

Flutter (Dart SDK ^3.7.0), Material 3, Provider for state. Backend is Firebase: Auth, Cloud Firestore, Storage, Messaging, App Check, plus Cloud Functions (Node 22, plain JS) in `functions/`. Google Maps and QR codes for location and sharing. Web build deployed on Netlify.

## Key files and dirs

- `lib/main.dart`: entry point, routing, Firebase init.
- `lib/api/`: Firebase service wrappers (auth, travel plans, users).
- `lib/providers/`: Provider state (travel plans, user).
- `lib/screens/`: UI pages grouped by feature (auth, home, add_travel, friends, profile).
- `lib/models/`, `lib/widgets/`, `lib/theme/`, `lib/utils/`: data classes, shared UI, styling, helpers.
- `functions/index.js`: Cloud Functions.
- `firebase.json`, `pubspec.yaml`, `analysis_options.yaml`: config.
- `test/widget_test.dart`: the only test.

## Commands

App (run from repo root):
- Install: `flutter pub get`
- Dev: `flutter run`
- Build: `flutter build apk` (or `web`, etc.)
- Test: `flutter test`
- Lint: `flutter analyze` (flutter_lints defaults)

Functions (run in `functions/`): `npm run serve` (emulator), `npm run deploy`, `npm run logs`. The `lint` script is a no-op echo.

## Conventions and gotchas

- The Dart package is named `travel_app`, so imports are `package:travel_app/...` even though the repo is travel-buddy.
- `functions/package.json` contains an unresolved git merge conflict (lines 5-9, `<<<<<<< HEAD` markers). Fix before touching functions or running npm there.
- Running the app needs Firebase config (`android/app/google-services.json` or platform equivalent) and a Google Maps API key in `android/app/src/main/AndroidManifest.xml`; see README.
- Root `travel_app/` dir is stray build output, not source. Release keystores (`my-release-key.jks`, `.keystore`) are committed at root; do not delete or reuse them.
- CI (`.github/workflows/pr-checks.yml`) requires semantic PR titles and a closing keyword like `Closes #123` in the PR body. No build or test runs in CI.
- Code is heavily DartDoc-commented; keep that style in `lib/`.
