# GitHub Copilot Instructions — Pardix Browser

## What this project is

A Flutter mobile browser app for Android and iOS. Package name `com.dino.pardix`. Built with Flutter SDK ^3.10.0, using Clean Architecture and flutter_bloc for state management.

## Architecture

```
lib/
├── core/          # Shared infrastructure (services, utils, resources, API client)
├── domain/        # Pure Dart: entities, abstract repos, use case base
├── data/          # Implements domain: StorageService, DownloadService, TabRepositoryImpl
├── features/      # Feature modules: download, media, search, tabs, webview
└── presentation/  # Top-level pages: HomePage, history sheet, mini URL bar
```

Dependency direction: `presentation → features → domain ← data`

## BLoC (State Management)

All feature state is managed by BLoC. The five main BLoCs:

| BLoC | Manages |
|------|---------|
| `TabBloc` | Tabs list, active tab, incognito mode, loaded resource URLs |
| `SearchBloc` | Search query, engine selection, suggestions, history |
| `MediaBloc` | Images/videos/audio extracted from loaded pages |
| `DownloadBloc` | Download queue (max 5 concurrent), pause/resume |
| `ConnectivityBloc` | Network online/offline status |

BLoC events follow `NounVerbEvent` naming: `TabAddEvent`, `DownloadStartEvent`, `MediaFilterChangedEvent`.

## Coding Patterns to Follow

```dart
// ✅ Logging — 6 levels, use the right one
AppLogger.verbose('Tag', 'granular trace');                           // dev only
AppLogger.debug('Tag', 'debug info: $value');                        // dev only
AppLogger.info('Tag', 'notable event');                              // breadcrumb in prod
AppLogger.warning('Tag', 'recoverable', error: e);                   // Crashlytics breadcrumb
AppLogger.error('Tag', 'caught exception', error: e, stackTrace: s); // Crashlytics non-fatal
AppLogger.fatal('Tag', 'unrecoverable', error: e, stackTrace: s);   // Crashlytics fatal

// ✅ Firebase Analytics event
AppLogger.event(AnalyticsEvent.tabOpened, params: {
  AnalyticsParam.isIncognito: false,
  AnalyticsParam.tabCount: tabs.length,
});

// ✅ Colors
color: AppColors.primary

// ✅ Storage
await storageService.saveTabs(tabs);

// ✅ Dispatching BLoC events
context.read<TabBloc>().add(const TabAddEvent());

// ✅ Reacting to BLoC state
BlocBuilder<TabBloc, TabState>(
  builder: (context, state) => Text(state.activeTab?.title ?? ''),
)
```

## Patterns to Avoid

```dart
// ❌ Never use print()
print('debug');  // use AppLogger.debug()

// ❌ Never use deprecated Logger
Logger.show('msg');  // use AppLogger.debug('Tag', 'msg')
Logger.error(e, s);  // use AppLogger.error('Tag', 'msg', error: e, stackTrace: s)

// ❌ Never call Firebase directly
FirebaseCrashlytics.instance.recordError(e, s);  // use AppLogger.error()/fatal()
FirebaseAnalytics.instance.logEvent(name: 'x'); // use AppLogger.event(AnalyticsEvent.x)

// ❌ Never hardcode analytics strings
analytics.logEvent(name: 'tab_opened'); // use AnalyticsEvent.tabOpened constant

// ❌ Never hardcode colors
color: Colors.blue  // use AppColors

// ❌ Never write to SharedPreferences directly
prefs.setString('tabs', json);  // use StorageService

// ❌ Never add feature state to StatefulWidget
setState(() { _tabs = newTabs; });  // use TabBloc

// ❌ Never create bare Dio instances
final dio = Dio();  // use ApiClient

// ❌ Never edit .freezed.dart files
// Edit the source file and run: dart run build_runner build --delete-conflicting-outputs
```

## Log Level Guide

| Situation | Level |
|-----------|-------|
| Tracing request/response internals | `verbose` |
| Variable values during dev | `debug` |
| User action, page load, feature used | `info` |
| Unexpected state, fallback used | `warning` |
| Caught exception in try/catch | `error` |
| Unrecoverable, app cannot continue | `fatal` |
| User action to track in Analytics | `.event()` |

## File Organization

New feature structure:
```
lib/features/<feature_name>/
├── bloc/
│   ├── <feature>_bloc.dart
│   ├── <feature>_event.dart
│   └── <feature>_state.dart
├── widgets/
│   └── <feature>_page.dart
└── services/   # (optional, if feature-scoped service needed)
```

## Key Files for Context

- `lib/features/tabs/bloc/tab_bloc.dart` — how BLoC is structured
- `lib/data/services/storage_service.dart` — how persistence works
- `lib/core/resources/app_colors.dart` — all app colors
- `lib/core/logger/app_logger.dart` — **central logger** (use this)
- `lib/core/logger/analytics_event.dart` — Analytics event + param constants

## After Editing @freezed Files

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Before Committing

```bash
flutter analyze   # must pass
dart format lib/  # apply formatting
flutter test      # must pass
```
