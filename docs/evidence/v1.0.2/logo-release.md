# Pardix v1.0.2 Logo Release Evidence

## Scope

- Version: `1.0.2+7`
- Android package: `com.dino.pardix`
- Release artifact: `build/app/outputs/bundle/release/app-release.aab`

## Logo Check

- Android launcher icon source: `assets/logo/app_icon.png`
- Play Store listing icon asset: `assets/logo/play_store_icon.png`
- The Android launcher resources generated from `assets/logo/app_icon.png` already match the current blue/white Pardix logo.
- The old orange/purple logo observed in Google Play Console is the Store Listing icon, which is managed separately from the app bundle launcher icon.

## Validation

- `dart run flutter_launcher_icons`
- `flutter test`
- `flutter build appbundle --release`

## Artifact

- AAB size: `54.9MB`
- SHA-256: `5093c440af9694ba40cee7cc88853a086df96c48ffaec377a8f341aad634b759`
