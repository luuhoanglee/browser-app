# Pardix Browser v1.0.3+8 Release Evidence

Date: 2026-07-22
Branch: `v1.0.3`
Device: Android emulator `emulator-5554`

## Build

```bash
flutter build apk --release
flutter build appbundle --release
```

Output:

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- AAB SHA-256: `7e2cc971d8a2a4b5d6faadfdd8ef14003b53804301468b6b4b207220392b647c`

## Validation

```bash
flutter test
```

Result: passed, 1 test.

```bash
flutter analyze
```

Result: failed with 1906 existing analyzer issues. The output is dominated by existing lint/warning debt in app code and vendored `packages/flutter_inappwebview`; the release APK and AAB builds completed successfully.

## Appium Screenshot Runs

```bash
EVIDENCE_DIR=docs/evidence/v1.0.3/screenshots \
APK_PATH=build/app/outputs/flutter-apk/app-release.apk \
APPIUM_DEVICE_NAME=emulator-5554 \
node appium_tests/split_view_smoke_test.mjs
```

```bash
EVIDENCE_DIR=docs/evidence/v1.0.3/screenshots \
APK_PATH=build/app/outputs/flutter-apk/app-release.apk \
APPIUM_DEVICE_NAME=emulator-5554 \
node appium_tests/warp_smoke_test.mjs
```

Screenshots:

- `docs/evidence/v1.0.3/screenshots/01-home.png` - home screen
- `docs/evidence/v1.0.3/screenshots/02-warp-sheet.png` - WARP / 1.1.1.1 sheet
- `docs/evidence/v1.0.3/screenshots/01-split-portrait.png` - split view portrait
- `docs/evidence/v1.0.3/screenshots/02-split-portrait-resized.png` - split resize gesture executed in portrait
- `docs/evidence/v1.0.3/screenshots/03-split-landscape.png` - split view landscape

Note: the portrait resize screenshot has the same SHA-256 as the initial portrait split screenshot on the emulator run, so the resize gesture did not produce a visually different captured frame.

## Screenshot SHA-256

```text
524d8afc284fcb3def8fc8f028e7cf05f7e23a135a7fe304c36f648eef7d4619  docs/evidence/v1.0.3/screenshots/01-home.png
716ae548b690853324633c391c89e2a68b825ab9fdd5498f91c8874aada85e05  docs/evidence/v1.0.3/screenshots/02-warp-sheet.png
83f8379d330c6cf42dad1d1024715cd2b705cc3e9be40c10deab0f658d683496  docs/evidence/v1.0.3/screenshots/01-split-portrait.png
83f8379d330c6cf42dad1d1024715cd2b705cc3e9be40c10deab0f658d683496  docs/evidence/v1.0.3/screenshots/02-split-portrait-resized.png
6ccc9101006f4284ed9f8dfde40eed1b6754d7e9b2aaf27e7f7b731a824ed57f  docs/evidence/v1.0.3/screenshots/03-split-landscape.png
```
