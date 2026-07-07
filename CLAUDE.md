# CLAUDE.md — Pardix Browser

This file gives Claude Code the context needed to work effectively in this repository. Read it before making any changes.

## Project Identity

- **App:** Pardix (Blackdog Browser) — a feature-rich mobile browser
- **Package:** `com.dino.pardix`
- **Flutter SDK:** ^3.10.0 / Dart ^3.10.0
- **Platforms:** Android (primary), iOS
- **Entry point:** `lib/main.dart`
- **Main screen:** `lib/presentation/pages/home/home_page.dart`

## Architecture at a Glance

Clean Architecture + BLoC. Dependency direction: Presentation → Features → Domain ← Data.

```
lib/
├── core/          # Shared: API client, services, utils, resources
├── data/          # Implementations: TabRepositoryImpl, StorageService, DownloadService
├── domain/        # Contracts: TabEntity, TabRepository, UseCase base
├── features/      # Self-contained modules (each has bloc/ + widgets/ + services/)
│   ├── download/  # DownloadBloc — queue, pause/resume, max 5 concurrent
│   ├── media/     # MediaBloc — extract images/video/audio from loaded pages
│   ├── search/    # SearchBloc — multi-engine, suggestions, history
│   ├── tabs/      # TabBloc — CRUD, incognito mode, thumbnail capture
│   └── webview/   # WebViewPage — rendering, ad blocking, JS injection
└── presentation/  # HomePage (main screen), history sheet, mini URL bar
```

## Critical Files

| File | What it does |
|------|-------------|
| `lib/main.dart` | App entry, Firebase init, deep link MethodChannel, crash guard |
| `lib/presentation/pages/home/home_page.dart` | Main UI (1,248 lines) — tab management, URL bar, navigation |
| `lib/features/webview/widgets/webview_page.dart` | WebView (1,375 lines) — content blocking, JS injection, ad block |
| `lib/features/tabs/bloc/tab_bloc.dart` | TabBloc — owns all tab state, incognito flag, resource list |
| `lib/features/download/bloc/download_bloc.dart` | DownloadBloc — download queue, progress, pause/resume |
| `lib/features/search/bloc/search_bloc.dart` | SearchBloc — query, engine, suggestions, history |
| `lib/features/media/bloc/media_bloc.dart` | MediaBloc — media resource classification and filtering |
| `lib/data/services/storage_service.dart` | Persists tabs + history to SharedPreferences (debounced 2s) |
| `lib/data/services/download_service.dart` | Dio-based downloader with pause/resume via Range header |
| `lib/features/webview/services/content_blocker_service.dart` | Loads ad domain blocklist from `assets/blockerList.json` |
| `lib/features/webview/services/webview_interceptor.dart` | Intercepts all WebView requests |
| `lib/core/utils/media_utils.dart` | Classifies URLs as image/video/audio/unknown |
| `lib/core/config/flavor_config.dart` | App flavor (dev/staging/prod) with API keys |
| `lib/core/logger/app_logger.dart` | **Central logger** — 6 levels, Firebase Analytics + Crashlytics routing |
| `lib/core/logger/analytics_event.dart` | All Analytics event names and parameter key constants |

## State Management Rules

- **All state lives in BLoC.** Never manage feature state in widget `setState`.
- `TabBloc` is the source of truth for tabs, active tab, incognito mode, and loaded resources.
- `MediaBloc` reads from `TabBloc.loadedResources` — it does not own resource collection.
- BLoCs are provided at `HomePage` level via `MultiBlocProvider`.
- Events are named `NounVerbEvent` (e.g., `TabRemoveEvent`, `DownloadStartEvent`).
- Use `Equatable` on all events and states. Use `Freezed` for sealed state unions.

## Code Generation

The project uses `freezed` for immutable classes. After editing any `@freezed` file:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.freezed.dart`, `*.g.dart`) are committed to the repo — do not delete them.

## Commands

```bash
flutter pub get                                          # Install dependencies
dart run build_runner build --delete-conflicting-outputs # Regenerate Freezed files
flutter analyze                                          # Static analysis
dart format lib/                                         # Format code
flutter test                                             # Run tests
flutter run -d android                                   # Run on Android
flutter build apk --release                              # Release APK
flutter build appbundle --release                        # Play Store AAB
```

## Conventions

### Files
- `snake_case.dart` for file names
- Group by feature, not by type (bloc/event/state stay together in `feature/bloc/`)
- New features go in `lib/features/<feature_name>/`

### Naming
- Classes: `PascalCase`
- Methods/variables: `camelCase`
- Private members: `_leadingUnderscore`
- Constants: `camelCase` (not SCREAMING_SNAKE)
- BLoC events: `NounVerbEvent` — e.g., `TabAddEvent`, `MediaFilterChangedEvent`

### Logging

**Never use `print()` or the deprecated `Logger` class.** Always use `AppLogger`:

```dart
// Import
import 'package:browser_app/core/logger/app_logger.dart';
import 'package:browser_app/core/logger/analytics_event.dart'; // for .event()

// 6 levels — pick the right one
AppLogger.verbose('Tag', 'Granular trace');           // dev only
AppLogger.debug('Tag', 'Debug info: $value');         // dev only
AppLogger.info('Tag', 'Notable event');               // breadcrumb in release
AppLogger.warning('Tag', 'Recoverable issue', error: e);     // Crashlytics breadcrumb
AppLogger.error('Tag', 'Caught exception', error: e, stackTrace: s); // Crashlytics non-fatal
AppLogger.fatal('Tag', 'Crash', error: e, stackTrace: s);    // Crashlytics fatal

// Firebase Analytics event (release only)
AppLogger.event(AnalyticsEvent.searchPerformed, params: {
  AnalyticsParam.engine: 'google',
  AnalyticsParam.queryLength: query.length,
});
```

**Tag** = class or feature name: `'TabBloc'`, `'WebView'`, `'Download'`, `'Search'`, `'Storage'`.

| Level | Debug | Release |
|-------|-------|---------|
| VERBOSE / DEBUG | console | suppressed |
| INFO | console | Crashlytics breadcrumb |
| WARNING | console | breadcrumb + non-fatal (if error) |
| ERROR | console | Crashlytics non-fatal |
| FATAL | console | Crashlytics fatal |
| `.event()` | console | Firebase Analytics |

### Colors, Strings, Sizes
Never hardcode — use `AppColors`, `AppStrings`, `AppSizes` from `lib/core/resources/`.

### API Calls
Use `ApiClient` from `lib/core/api/api_client.dart`. Do not create bare `http.Client` or raw `Dio` instances outside of services.

## What NOT to Do

- **Do not add state to widgets** that belongs in a BLoC — home_page.dart already has too much local state; don't add more.
- **Do not write to SharedPreferences directly** — always go through `StorageService`.
- **Do not access `context.read<XBloc>()` deep in widget trees** — pass callbacks from the top or use `BlocBuilder` locally.
- **Do not add `await`-less `Future` calls** that mutate state (especially `saveHistory()`).
- **Do not store thumbnails as large base64 in SharedPreferences** — keep size reasonable or move to filesystem.
- **Do not commit** `.key.properties`, `*.jks`, `google-services.json`, `GoogleService-Info.plist`.
- **Do not skip `flutter analyze`** before proposing changes — the project must stay lint-clean.
- **Do not modify files in `packages/flutter_inappwebview/`** without understanding the local fork — it has custom patches.

## Known Issues / Tech Debt

| Issue | Location | Risk |
|-------|----------|------|
| `home_page.dart` is 1,248 lines | `presentation/pages/home/` | Maintainability |
| Loaded resources list has no size cap | `TabBloc.AddLoadedResourceEvent` | Memory |
| `WebViewController` disposal not explicit | `home_page.dart` controllers map | Memory leak |
| Dual navigation history (BLoC + local map) | `home_page.dart _navHistory` | Consistency |
| No timeout on search suggestions fetch | `SearchService` | Hang risk |
| FCM token stored unencrypted | `SharedPreferences` | Low security risk |

## Adding a New Feature

1. Create `lib/features/<name>/`
2. Add `bloc/` with `_bloc.dart`, `_event.dart`, `_state.dart`
3. Add `widgets/` for UI
4. Register BLoC in `home_page.dart` `MultiBlocProvider`
5. Write unit tests in `test/features/<name>/`
6. Document in `docs/features.md`

## Testing

```bash
flutter test                      # All tests
flutter test test/features/tabs/  # Specific feature
```

Use `bloc_test` for BLoC unit tests. Widget tests use `BlocProvider.value` with mock BLoCs. Avoid mocking storage in integration paths — use real SharedPreferences in test mode.

## Assets

| Asset | Purpose |
|-------|---------|
| `assets/blockerList.json` | Ad/tracker domain blocklist (100+ domains) |
| `assets/block_ad_pattern.txt` | URL pattern blocklist (regex) |
| `assets/logo/` | App icons |

## Firebase

Required files (not in git):
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## Platform Notes

- **Android signing:** Configure `android/.key.properties` — never commit it
- **Foreground service:** Required for downloads on Android 8+, configured in `AndroidManifest.xml`
- **iOS content blocking:** Uses `WKContentRuleList` via `IOSContentBlockerService` (different from Android)
- **Cleartext traffic:** Enabled (`android:usesCleartextTraffic="true"`) — required for HTTP URLs in WebView
- **Java 17 desugaring:** Enabled in `build.gradle.kts` for modern Dart/Flutter features
