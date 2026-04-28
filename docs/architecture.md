# Architecture

## Overview

Pardix Browser follows **Clean Architecture** with **BLoC** (Business Logic Component) for state management. The codebase is organized into four main layers with strict dependency rules: outer layers depend on inner layers, never the reverse.

```
┌─────────────────────────────────────────────┐
│              Presentation Layer             │
│         (UI widgets, pages, BLoC)           │
├─────────────────────────────────────────────┤
│               Features Layer                │
│    (download, media, search, tabs, webview) │
├─────────────────────────────────────────────┤
│                Data Layer                   │
│      (repositories, services, models)       │
├─────────────────────────────────────────────┤
│               Domain Layer                  │
│       (entities, use cases, contracts)      │
└─────────────────────────────────────────────┘
```

## Layers

### Domain Layer (`lib/domain/`)

The innermost layer. Contains pure Dart classes with zero Flutter or third-party dependencies.

```
domain/
├── entities/
│   └── tab_entity.dart          # TabEntity — core tab data model
├── repositories/
│   └── tab_repository.dart      # Abstract contract for tab persistence
└── usecases/
    └── usecase.dart             # Generic UseCase<Params, Result> base class
```

**Rules:**
- No imports from `data/`, `features/`, or `presentation/`
- Only plain Dart — no Flutter widgets, no Dio, no SharedPreferences

### Data Layer (`lib/data/`)

Implements domain contracts. Handles persistence, serialization, and external services.

```
data/
├── models/
│   └── tab_model.dart           # TabModel (JSON serialization, extends TabEntity)
├── repositories/
│   └── tab_repository_impl.dart # Implements TabRepository via StorageService
└── services/
    ├── download_service.dart            # Dio-based file downloader with pause/resume
    ├── download_notification_service.dart # Notification updates for downloads
    └── storage_service.dart             # SharedPreferences tab/history persistence
```

### Features Layer (`lib/features/`)

Self-contained feature modules, each with their own BLoC, widgets, and services.

```
features/
├── download/         # DownloadBloc — manage up to 5 concurrent downloads
├── media/            # MediaBloc — extract and play images/videos/audio from pages
├── search/           # SearchBloc — suggestions, history, multi-engine support
├── tabs/             # TabBloc — CRUD tabs, incognito mode, thumbnail capture
└── webview/          # WebViewPage — rendering, ad blocking, content interception
```

Each feature follows the same internal structure:

```
feature_name/
├── bloc/
│   ├── feature_bloc.dart    # Business logic
│   ├── feature_event.dart   # Input events
│   └── feature_state.dart   # Output state
├── widgets/                 # Feature-specific UI
└── services/                # Feature-scoped services (if needed)
```

### Presentation Layer (`lib/presentation/`)

Top-level pages and shared UI widgets.

```
presentation/
└── pages/
    └── home/
        ├── home_page.dart            # Main app screen (tabs, URL bar, navigation)
        ├── models/
        │   └── quick_access_item.dart
        └── widgets/
            ├── history_sheet.dart    # Browsing history bottom sheet
            └── mini_url_bar.dart     # Compact URL bar shown while scrolling
```

### Core Layer (`lib/core/`)

Shared infrastructure used by all layers.

```
core/
├── api/              # Dio client, interceptors (auth, error, logging), response models
├── config/           # App constants, theme, deep link config, flavor/env settings
├── enum/             # App-wide enums (MediaType, ConnectNetwork, Flavor, API)
├── extentions/       # String and DateTime Dart extensions
├── logger/           # Custom structured logger
├── mixin/            # Reusable Flutter mixins (keyboard dismiss, load more, pop scope)
├── resources/        # AppColors, AppStrings, AppSizes, AppAssets, AppStyle
├── services/         # Firebase, FCM, connectivity, local notifications, OxoDB
├── shared/           # BaseModelCache, CacheManager
└── utils/            # Debouncer, MediaUtils, validators, router utils
```

## State Management

All state is managed via `flutter_bloc`. See [state-management.md](state-management.md) for full BLoC reference.

### BLoC Hierarchy in `HomePage`

```
MultiBlocProvider
├── TabBloc            # Owns tab list, active tab, incognito flag
├── SearchBloc         # Owns search query, engine, suggestions, history
├── MediaBloc          # Owns extracted media resources per page
├── DownloadBloc       # Owns download queue and progress
└── ConnectivityBloc   # Owns network status
```

## Data Flow

### Opening a URL

```
User types URL
  → SearchBloc.PerformSearchEvent
  → HomePage formats URL (validates: is URL or search query?)
  → InAppWebViewController.loadUrl()
  → WebViewPage.onLoadStart / onLoadStop callbacks
  → TabBloc.UpdateTabEvent (title, URL, progress)
  → StorageService.saveTabs() [debounced 2s]
```

### Tab Thumbnail Capture

```
WebViewPage.onLoadStop
  → HomePage._captureThumbnail()
  → RepaintBoundary.toImage() OR WebViewController.takeScreenshot()
  → TabBloc.UpdateTabEvent(thumbnail: base64)
  → StorageService.saveTabs() [debounced 2s]
```

### Media Extraction

```
WebViewPage.onLoadResource (each resource loaded)
  → TabBloc.AddLoadedResourceEvent(url)
  → MediaBloc.MediaExtractFromResources
  → MediaUtils.detectType(url) → image / video / audio / unknown
  → MediaState.resources updated (filtered list)
  → MediaGallerySheet displays results
```

## Dependency Injection

Dependencies are wired manually at the BLoC creation point (no service locator). Each `BlocProvider` in `home_page.dart` constructs its BLoC with required dependencies:

```dart
BlocProvider(
  create: (_) => DownloadBloc(
    downloadService: DownloadService(),
    notificationService: DownloadNotificationService(),
  ),
)
```

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Local fork of `flutter_inappwebview` | Needed custom interception and script injection not available upstream |
| `RepaintBoundary` for thumbnails | Captures Flutter widget trees (empty page) without WebView screenshot overhead |
| Dual navigation history (WebView + custom) | WebView history resets on recreation; custom map preserves history across tab switches |
| Debounced SharedPreferences writes | Prevents excessive I/O during rapid tab/URL updates |
| Foreground service for downloads | Required on Android 8+ to maintain background operation and show persistent notification |
