# v1.0.2 Split View Evidence

Task: #14 Split 2 tabs with portrait top/bottom, landscape left/right, and draggable divider.

## Build

- `flutter build apk --release`
- Output: `build/app/outputs/flutter-apk/app-release.apk`

## Appium E2E

- Device: `emulator-5554`
- Command:

```bash
EVIDENCE_DIR=docs/evidence/v1.0.2/split-view \
APK_PATH=build/app/outputs/flutter-apk/app-release.apk \
APPIUM_DEVICE_NAME=emulator-5554 \
node appium_tests/split_view_smoke_test.mjs
```

- Result: passed
- Coverage:
  - Opens tab sheet.
  - Adds a second tab.
  - Enables split view through `Use tab in split view`.
  - Captures portrait top/bottom split.
  - Executes divider drag gesture.
  - Rotates emulator with adb and captures landscape left/right split.

## Evidence Files

- `docs/evidence/v1.0.2/split-view/01-split-portrait.png`
- `docs/evidence/v1.0.2/split-view/02-split-portrait-resized.png`
- `docs/evidence/v1.0.2/split-view/03-split-landscape.png`
- `docs/evidence/v1.0.2/split-view/appium-server.log`

## Checks

- `node --check appium_tests/split_view_smoke_test.mjs`: passed
- `dart format ...`: passed
- `flutter test`: passed
- `flutter analyze <touched files>`: no compile errors; existing warnings/infos remain in `tab_bloc.dart`, `tabs_sheet.dart`, and `home_page.dart`.

Note: Appium executed the divider drag command successfully, but the two portrait screenshots remained visually identical in this emulator run. Manual divider drag should be verified on device before Play release acceptance.
