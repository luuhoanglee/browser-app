# GEMINI.md — Pardix Browser

Context file for Google Gemini Code Assist and Gemini CLI when working in this repository.

## Project Summary

| Field | Value |
|-------|-------|
| App name | Pardix (Blackdog Browser) |
| Package | `com.dino.pardix` |
| Type | Flutter mobile browser (Android + iOS) |
| Flutter SDK | ^3.10.0 |
| Dart SDK | ^3.10.0 |
| State management | flutter_bloc ^8.1.6 |
| Architecture | Clean Architecture |
| Entry point | `lib/main.dart` |
| Main screen | `lib/presentation/pages/home/home_page.dart` |

## Codebase Map

```
lib/
├── core/                    # Infrastructure layer
│   ├── api/                 # Dio client + interceptors (auth, error, logging)
│   ├── config/              # Constants, themes, deep links, flavor config
│   ├── enum/                # MediaType, ConnectNetwork, Flavor, API enums
│   ├── extentions/          # String + DateTime Dart extensions
│   ├── logger/              # AppLogger (debug/info/warning/error)
│   ├── mixin/               # KeyboardDismiss, LoadMore, PopScope mixins
│   ├── resources/           # AppColors, AppStrings, AppSizes, AppAssets
│   ├── services/            # Firebase, FCM, connectivity, notifications
│   ├── shared/              # BaseModelCache, CacheManager
│   └── utils/               # Debouncer, MediaUtils, validators
├── domain/                  # Domain layer (pure Dart)
│   ├── entities/            # TabEntity
│   ├── repositories/        # Abstract TabRepository
│   └── usecases/            # Generic UseCase<P, R> base
├── data/                    # Data layer
│   ├── models/              # TabModel (JSON serialization)
│   ├── repositories/        # TabRepositoryImpl
│   └── services/            # DownloadService, StorageService, NotificationService
├── features/                # Feature modules
│   ├── download/            # DownloadBloc, DownloadSheet, download queue
│   ├── media/               # MediaBloc, ImageViewer, VideoPlayer, AudioPlayer
│   ├── search/              # SearchBloc, SearchPage, engine selector
│   ├── tabs/                # TabBloc, TabBarWidget
│   └── webview/             # WebViewPage, interceptor, content blocker
└── presentation/
    └── pages/home/          # HomePage (root screen), HistorySheet, MiniUrlBar
```

## BLoC Reference

### TabBloc (`lib/features/tabs/bloc/tab_bloc.dart`)
**State fields:** `tabs`, `activeTab`, `isIncognitoMode`, `loadedResources`, `normalModeActiveTabId`, `incognitoModeActiveTabId`

**Key events:** `TabAddEvent`, `TabRemoveEvent`, `TabSelectEvent`, `TabUpdateEvent`, `AddLoadedResourceEvent`, `ClearLoadedResourcesEvent`, `ToggleIncognitoModeEvent`

### SearchBloc (`lib/features/search/bloc/search_bloc.dart`)
**State fields:** `query`, `engine`, `suggestions`, `history`, `trending`, `isLoadingSuggestions`

**Key events:** `UpdateQueryEvent`, `SetEngineEvent`, `PerformSearchEvent`, `LoadHistoryEvent`, `LoadSuggestionsEvent`

### DownloadBloc (`lib/features/download/bloc/download_bloc.dart`)
**State fields:** `downloads` (list), `activeCount` (max 5)

**Key events:** `DownloadStartEvent`, `DownloadPauseEvent`, `DownloadResumeEvent`, `DownloadCancelEvent`, `DownloadBatchStartEvent`

### MediaBloc (`lib/features/media/bloc/media_bloc.dart`)
**State fields:** `resources`, `activeFilter`, `isLoading`

**Key events:** `MediaExtractFromResources`, `MediaFilterChanged`, `MediaRefreshRequested`

### ConnectivityBloc (`lib/core/services/connectivity/bloc/connectivity_bloc.dart`)
**States (Freezed):** `Connected`, `Disconnected`, `Unknown`

## Coding Rules

### Always
- Use `AppLogger` for logging (never `print`)
- Use `AppColors`, `AppStrings`, `AppSizes` for UI values
- Route all storage through `StorageService`
- Route all HTTP through `ApiClient`
- Add `Equatable` to BLoC events and states
- Run `dart run build_runner build` after editing `@freezed` sources
- Run `flutter analyze` before finalizing changes

### Never
- Put feature state in `StatefulWidget.setState` — use BLoC
- Call `SharedPreferences` directly — use `StorageService`
- Create a raw `Dio()` instance — use `ApiClient`
- Edit `*.freezed.dart` or `*.g.dart` files directly
- Edit `packages/flutter_inappwebview/` without explicit instruction
- Commit secrets (`.key.properties`, `*.jks`, `google-services.json`)

## Logging System

### Files

| File | Purpose |
|------|---------|
| `lib/core/logger/app_logger.dart` | Core logger — use this everywhere |
| `lib/core/logger/log_level.dart` | `LogLevel` enum (VERBOSE→FATAL) |
| `lib/core/logger/log_record.dart` | Structured log entry model |
| `lib/core/logger/analytics_event.dart` | `AnalyticsEvent` + `AnalyticsParam` constants |
| `lib/core/logger/logger.dart` | Legacy `Logger` class — `@Deprecated`, do not use |

### API

```dart
import 'package:browser_app/core/logger/app_logger.dart';
import 'package:browser_app/core/logger/analytics_event.dart';

// Leveled logs
AppLogger.verbose('Tag', 'trace message');
AppLogger.debug('Tag', 'debug: $value');
AppLogger.info('Tag', 'event occurred');
AppLogger.warning('Tag', 'recoverable issue', error: e);
AppLogger.error('Tag', 'caught error', error: e, stackTrace: s);
AppLogger.fatal('Tag', 'crash', error: e, stackTrace: s);

// Firebase Analytics (no-op in debug, sent in release)
AppLogger.event(AnalyticsEvent.searchPerformed, params: {
  AnalyticsParam.engine: 'google',
  AnalyticsParam.queryLength: 5,
});
```

### Firebase Routing

| Level | Release behavior |
|-------|-----------------|
| VERBOSE / DEBUG | suppressed |
| INFO | Crashlytics `.log()` breadcrumb |
| WARNING | breadcrumb + non-fatal (if error attached) |
| ERROR | `Crashlytics.recordError(fatal: false)` |
| FATAL | `Crashlytics.recordError(fatal: true)` |
| `.event()` | `FirebaseAnalytics.logEvent()` |

### Error Wiring (automatic via `FirebaseService`)

```
FlutterError.onError            → AppLogger.fatal()
PlatformDispatcher.instance.onError → AppLogger.fatal()
runZonedGuarded (main.dart)     → AppLogger.fatal()
```

All three are wired automatically. No manual setup needed.

### Analytics Events Quick Reference

```dart
// Tabs
AppLogger.event(AnalyticsEvent.tabOpened, params: {AnalyticsParam.isIncognito: false});
AppLogger.event(AnalyticsEvent.tabClosed);
AppLogger.event(AnalyticsEvent.incognitoToggled);

// Search
AppLogger.event(AnalyticsEvent.searchPerformed, params: {
  AnalyticsParam.engine: 'google',
  AnalyticsParam.queryLength: query.length,
});

// Downloads
AppLogger.event(AnalyticsEvent.downloadStarted, params: {
  AnalyticsParam.fileType: 'mp4',
  AnalyticsParam.fileSizeKb: 10240,
});
AppLogger.event(AnalyticsEvent.downloadCompleted, params: {AnalyticsParam.success: true});

// Media
AppLogger.event(AnalyticsEvent.mediaViewed, params: {AnalyticsParam.mediaType: 'video'});

// Ad blocking
AppLogger.event(AnalyticsEvent.adBlocked, params: {
  AnalyticsParam.blockReason: 'domain',
  AnalyticsParam.blockedCount: 1,
});
```

---

## Common Tasks

### Add a download
```dart
context.read<DownloadBloc>().add(DownloadStartEvent(url: url, filename: filename));
AppLogger.event(AnalyticsEvent.downloadStarted, params: {AnalyticsParam.fileType: ext});
```

### Add a tab
```dart
context.read<TabBloc>().add(TabAddEvent(url: 'https://example.com'));
AppLogger.event(AnalyticsEvent.tabOpened, params: {AnalyticsParam.tabCount: tabs.length});
```

### Detect media type from URL
```dart
final type = MediaUtils.detectType(url); // returns MediaType enum
```

### Log at correct level
```dart
AppLogger.debug('FeatureName', 'Verbose debug: $value');   // dev only
AppLogger.info('FeatureName', 'User did something');        // notable events
AppLogger.error('FeatureName', 'Failed', error: e, stackTrace: s); // exceptions
```

### Block a new ad domain
Add the domain string to `assets/blockerList.json`.

### Add a URL pattern to the blocklist
Add the regex pattern to `assets/block_ad_pattern.txt`.

## Build Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format lib/
flutter test
flutter run -d android
flutter build apk --release
flutter build appbundle --release
```

## Docs Reference
- Architecture: `docs/architecture.md`
- Features: `docs/features.md`
- BLoC details: `docs/state-management.md`
- Services: `docs/services.md`
- Setup: `docs/setup.md`
- Contributing: `docs/contributing.md`
