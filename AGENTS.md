# AGENTS.md — Pardix Browser

This file is for AI coding agents (OpenAI Codex, GitHub Copilot Workspace, Devin, and similar). It defines how agents should orient themselves in this repo, what tools to run, and what constraints to respect.

## Repository Overview

**Type:** Flutter mobile application (Android/iOS browser)  
**Package:** `com.dino.pardix`  
**Language:** Dart (Flutter SDK ^3.10.0)  
**State management:** flutter_bloc  
**Architecture:** Clean Architecture  

## Orientation: Where Things Live

Before writing any code, run these to orient yourself:

```bash
# Understand the project structure
find lib/ -type f -name "*.dart" | head -60

# Find where a concept lives
grep -r "DownloadBloc" lib/ --include="*.dart" -l
grep -r "TabEntity" lib/ --include="*.dart" -l

# Check what a BLoC manages
cat lib/features/tabs/bloc/tab_bloc.dart
cat lib/features/tabs/bloc/tab_event.dart
cat lib/features/tabs/bloc/tab_state.dart
```

## Layer Map

```
lib/core/           → shared infrastructure (never import from features/ or presentation/)
lib/domain/         → pure Dart entities + abstract contracts (no Flutter imports)
lib/data/           → implements domain contracts (storage, download, models)
lib/features/       → feature modules (each is self-contained)
lib/presentation/   → top-level pages (HomePage, sheets)
```

Dependency rule: **presentation → features → domain ← data**

## BLoC Registry

| BLoC | File | Manages |
|------|------|---------|
| `TabBloc` | `lib/features/tabs/bloc/tab_bloc.dart` | Tabs, active tab, incognito, loaded resources |
| `SearchBloc` | `lib/features/search/bloc/search_bloc.dart` | Query, engine, suggestions, history |
| `MediaBloc` | `lib/features/media/bloc/media_bloc.dart` | Media resources (images/video/audio) |
| `DownloadBloc` | `lib/features/download/bloc/download_bloc.dart` | Download queue, progress |
| `ConnectivityBloc` | `lib/core/services/connectivity/bloc/connectivity_bloc.dart` | Network status |

All BLoCs are registered in `MultiBlocProvider` inside `home_page.dart`.

## Mandatory Checks Before Submitting Changes

```bash
# 1. Static analysis — must pass with zero errors
flutter analyze

# 2. Format — must be applied
dart format lib/

# 3. Tests — must pass
flutter test

# 4. If Freezed files were modified, regenerate
dart run build_runner build --delete-conflicting-outputs
```

If any of these fail, fix before submitting.

## Code Generation Awareness

Files ending in `.freezed.dart` or `.g.dart` are **generated** — do not edit them manually. Edit the source file (e.g., `connectivity_event.dart`) and re-run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files are committed to the repo.

## Task Patterns

### Adding a BLoC Event

1. Add the event class to `feature_event.dart`
2. Add handler `on<NewEvent>(_handleNewEvent)` in `feature_bloc.dart`
3. Implement the handler method
4. Add state field if state needs to change shape
5. Write a `bloc_test` unit test

### Adding a New Screen / Sheet

1. Create widget file in `lib/features/<feature>/widgets/` or `lib/presentation/pages/`
2. Use `BlocBuilder` / `BlocListener` for state-driven UI
3. Do not call `context.read<XBloc>()` from deeply nested children — pass callbacks
4. Register any new routes in `lib/core/utils/router_utils.dart` if needed

### Modifying WebView Behavior

- Interception logic → `lib/features/webview/services/webview_interceptor.dart`
- JavaScript injection → `lib/features/webview/widgets/webview_page.dart` (search for `evaluateJavascript`)
- Ad blocking → `lib/features/webview/services/content_blocker_service.dart` (domains) or `assets/block_ad_pattern.txt` (patterns)
- iOS-specific → `lib/features/webview/services/ios_content_blocker_service.dart`

### Modifying Download Flow

```
User action → DownloadBloc.DownloadStartEvent
  → DownloadService.download() [Dio + Range header for resume]
  → DownloadBloc.DownloadProgressEvent (internal, via stream)
  → DownloadNotificationService.update()
  → ForegroundDownloadService (keeps alive in background)
```

### Persisting Data

Always use `StorageService` (`lib/data/services/storage_service.dart`):
- Writes are debounced 2 seconds — do not add direct SharedPreferences calls
- For new data types, add a method to `StorageService`, not inline `prefs.set*` calls

## Logging

Use `AppLogger` from `lib/core/logger/app_logger.dart`. Never use `print()` or the deprecated `Logger` class.

```dart
AppLogger.verbose('Tag', 'trace');
AppLogger.debug('Tag', 'debug info');
AppLogger.info('Tag', 'notable event', params: {'key': 'value'});
AppLogger.warning('Tag', 'recoverable', error: e);
AppLogger.error('Tag', 'caught exception', error: e, stackTrace: s);
AppLogger.fatal('Tag', 'unrecoverable', error: e, stackTrace: s);

// Firebase Analytics (release only, no-op in debug)
AppLogger.event(AnalyticsEvent.tabOpened, params: {
  AnalyticsParam.isIncognito: false,
});
```

**Routing:**

| Level | Debug | Release |
|-------|-------|---------|
| VERBOSE / DEBUG | console | suppressed |
| INFO | console | Crashlytics breadcrumb |
| WARNING | console | breadcrumb + non-fatal |
| ERROR | console | Crashlytics non-fatal |
| FATAL | console | Crashlytics fatal |
| `.event()` | console | Firebase Analytics |

**Tag** = class/feature name (`'TabBloc'`, `'WebView'`, `'Download'`, `'Storage'`).

Analytics event constants live in `lib/core/logger/analytics_event.dart` — always use `AnalyticsEvent.*` and `AnalyticsParam.*` constants, never raw strings.

---

## Constraints

### Never Do
- Direct `SharedPreferences` access outside `StorageService`
- `print()` — use `AppLogger`
- `Logger.show()` / `Logger.error()` — deprecated, use `AppLogger`
- Raw Analytics/Crashlytics calls — route through `AppLogger`
- Hardcoded colors — use `AppColors` from `lib/core/resources/app_colors.dart`
- Hardcoded strings — use `AppStrings` from `lib/core/resources/app_strings.dart`
- Hardcoded sizes — use `AppSizes` from `lib/core/resources/app_size.dart`
- New bare `Dio` / `http.Client` instances — use `ApiClient`
- Widget `setState` for feature state — use BLoC
- Importing `features/` from `domain/` — violates clean architecture
- Modifying `packages/flutter_inappwebview/` without explicit instruction

### Never Commit
- `android/.key.properties`
- `android/app/*.jks`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- Any file with secrets, tokens, or passwords

## Testing Guidance

```
test/
└── widget_test.dart   # Currently only a placeholder — add tests alongside new features
```

Test locations:
- BLoC tests → `test/features/<feature>/bloc/`
- Widget tests → `test/features/<feature>/widgets/`
- Service tests → `test/core/services/`

Use `mocktail` or `mockito` for mocking. Use `bloc_test` for BLoC:

```dart
blocTest<TabBloc, TabState>(
  'emits updated state when tab added',
  build: () => TabBloc(repository: MockTabRepository()),
  act: (bloc) => bloc.add(const TabAddEvent()),
  expect: () => [isA<TabState>().having((s) => s.tabs, 'tabs', hasLength(1))],
);
```

## Environment

- `FLAVOR` dart-define controls flavor: `development` | `staging` | `production`
- Firebase config files must be placed manually (not in repo)
- Java 17 required for Android builds
- Android signing configured via `android/.key.properties`

## Common Pitfalls

| Pitfall | Why it matters |
|---------|---------------|
| Adding state to `home_page.dart` | Already 1,248 lines — any new state should go in a BLoC |
| Forgetting `buildrunner` after editing Freezed source | App will fail to compile |
| Calling `saveHistory()` without `await` | Data loss on fast exit |
| No limit on `loadedResources` | Memory grows unbounded on media-heavy pages |
| Disposing `WebViewController` from the controllers map | Currently not explicit — don't make it worse |

## Reference Docs

- `docs/architecture.md` — layer diagram, data flows, design decisions
- `docs/features.md` — feature specifications
- `docs/state-management.md` — full BLoC reference
- `docs/services.md` — all services and utilities
- `docs/setup.md` — environment setup
- `docs/contributing.md` — conventions and PR checklist
