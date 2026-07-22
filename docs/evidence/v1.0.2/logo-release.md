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
- `flutter analyze` currently reports the existing project baseline analyzer debt; the logo change does not add new analyzer issues.

## Artifact

- AAB size: `55.0MB`
- SHA-256: `da4abb0600aab83f1f6e22b766c3aff9a2407a85e3087c2b753934cb97704832`
