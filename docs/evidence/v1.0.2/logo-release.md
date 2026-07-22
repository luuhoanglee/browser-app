# Pardix v1.0.2 Logo Release Evidence

## Scope

- Version: `1.0.2+7`
- Android package: `com.dino.pardix`
- Release artifact: `build/app/outputs/bundle/release/app-release.aab`

## Logo Check

- Correct brand icon: orange/purple Pardix icon, matching the current Google Play Store listing.
- Previous Android launcher icon source: `assets/logo/app_icon.png` (old blue/white icon).
- New Android launcher icon source: `assets/logo/logo.png` (orange/purple icon).
- Regenerated launcher resources so the installed app icon matches the Google Play Store icon.

## Validation

- `dart run flutter_launcher_icons`
- `flutter test`
- `flutter build appbundle --release`
- `flutter build apk --release`
- `EVIDENCE_DIR=docs/evidence/v1.0.2 APK_PATH=build/app/outputs/flutter-apk/app-release.apk APPIUM_DEVICE_NAME=emulator-5554 node appium_tests/warp_smoke_test.mjs`
- `flutter analyze` currently reports the existing project baseline analyzer debt; the logo change does not add new analyzer issues.

## Android E2E

- Device: `emulator-5554` (`sdk_gphone64_arm64`, Android 15 / API 35)
- Installed package: `com.dino.pardix`
- Installed version: `versionCode=7`, `versionName=1.0.2`
- Appium driver: UiAutomator2
- Result: passed. App launched from the release APK, the `WARP / 1.1.1.1` control was visible, and tapping it opened the WARP sheet.
- Evidence screenshots:
  - `docs/evidence/v1.0.2/01-home.png` (`5878654500d37be0596026886adb149a503b8693c87550e03556db910884f779`)
  - `docs/evidence/v1.0.2/02-warp-sheet.png` (`8e18af1eacce48460695ed9e8bd14453a736a54ee27dc57273e53d22f66b55e5`)
  - `docs/evidence/v1.0.2/03-device-current.png` (`4bc649a666818f1f3a039ec65402b67d02a69fd85cded7d5e317a68aebfca6ae`)
- Appium log: `docs/evidence/v1.0.2/appium-server.log` (`5c9b3ec0178e361431c3ffa9e1752d6f3bbb8b67785cb2364002c5bafe28334d`)

## Artifact

- AAB size: `55.0MB`
- SHA-256: `da4abb0600aab83f1f6e22b766c3aff9a2407a85e3087c2b753934cb97704832`
- APK size: `68.0MB`
- APK SHA-256: `7fad33e2b0bb94baa131feb775ca8c42670f0964a483488b31739f1bdebccb26`
