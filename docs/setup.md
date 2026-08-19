# Setup Guide

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | ^3.10.0 |
| Dart SDK | ^3.10.0 |
| Java | 17 |
| Android Studio | Ladybug or later |
| Xcode (iOS) | 15+ |
| Android SDK | API 24+ (target: 35) |

## Clone and Install

```bash
git clone <repo-url>
cd browser_app
flutter pub get
```

## Code Generation

The project uses `freezed` for immutable state classes. After any changes to files annotated with `@freezed`, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

To watch for changes during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project (or use existing)
3. Enable: Authentication, Crashlytics, Cloud Messaging, Analytics

### 2. Android

1. Add Android app with package name `com.dino.pardix`
2. Download `google-services.json`
3. Place at `android/app/google-services.json`

### 3. iOS

1. Add iOS app with bundle ID matching your config
2. Download `GoogleService-Info.plist`
3. Place at `ios/Runner/GoogleService-Info.plist`

### 4. Verify

```bash
flutter run  # Should initialize Firebase without errors
```

## Android Signing

### Generate Keystore

```bash
keytool -genkey -v \
  -keystore android/app/release.jks \
  -alias pardix \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### Configure Key Properties

Create `android/.key.properties` (already in `.gitignore`):

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=pardix
storeFile=release.jks
```

> **Security:** Never commit `.key.properties` or any `.jks` file to version control.

### Build Release APK

```bash
flutter build apk --release
```

### Build Release AAB (Play Store)

```bash
flutter build appbundle --release
```

## iOS Signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target → Signing & Capabilities
3. Set Team and Bundle Identifier
4. Enable automatic signing or configure provisioning profiles manually

```bash
flutter build ipa --release
```

## Flavors

The app supports build flavors via `lib/core/config/flavor_config.dart` and `lib/core/enum/flavor/flavor.dart`.

### Defined Flavors

| Flavor | Usage |
|--------|-------|
| `development` | Local development, debug logging enabled |
| `staging` | QA testing environment |
| `production` | Release build |

### Running with Flavor

```bash
flutter run --flavor development --dart-define=FLAVOR=development
flutter run --flavor production --dart-define=FLAVOR=production
```

### Environment Config

`lib/core/config/environment/env.dart` reads `--dart-define` values:

```dart
const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'development');
```

## Assets

Assets are declared in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/blockerList.json       # Ad block domain list
    - assets/block_ad_pattern.txt   # URL pattern blocklist
    - assets/logo/                  # App icons and logos
```

To regenerate app icons after changing `assets/logo/`:

```bash
dart run flutter_launcher_icons
```

## Running Tests

```bash
# Unit tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Common Issues

### Build fails: `minSdkVersion` error

The project uses `flutter.minSdkVersion` from `local.properties`. Ensure your `android/local.properties` has:

```properties
flutter.minSdkVersion=24
```

### `build_runner` conflict errors

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Firebase initialization failed

- Verify `google-services.json` is in `android/app/`
- Check the package name matches `com.dino.pardix`
- Run `flutter clean && flutter pub get`

### Foreground service crashes on Android 14+

Android 14 requires explicit foreground service type declaration. Verify `AndroidManifest.xml` contains:

```xml
<service
  android:name="..."
  android:foregroundServiceType="dataSync"/>
```

### WebView blank on first load (iOS)

Ensure `NSAppTransportSecurity` in `Info.plist` allows the target domain, or that `usesCleartextTraffic` equivalent is configured for iOS if loading HTTP URLs.
