# State Management

All state management uses `flutter_bloc`. This document is the BLoC reference for all features.

## BLoC Overview

| BLoC | File | Scope |
|------|------|-------|
| `TabBloc` | `lib/features/tabs/bloc/tab_bloc.dart` | Tab list, active tab, incognito, resources |
| `SearchBloc` | `lib/features/search/bloc/search_bloc.dart` | Search query, engine, suggestions, history |
| `MediaBloc` | `lib/features/media/bloc/media_bloc.dart` | Extracted media resources |
| `DownloadBloc` | `lib/features/download/bloc/download_bloc.dart` | Download queue and progress |
| `ConnectivityBloc` | `lib/core/services/connectivity/bloc/connectivity_bloc.dart` | Network status |
| `LocaleCubit` | `lib/core/services/locale/locale_cubit.dart` | App locale |
| `ApiCubit` | `lib/core/api/cubit/api_cubit.dart` | Global API request state |

---

## TabBloc

**File:** `lib/features/tabs/bloc/tab_bloc.dart`

### State: `TabState`

```dart
class TabState {
  final List<TabEntity> tabs;          // All tabs (filtered by incognito mode)
  final TabEntity? activeTab;          // Currently selected tab
  final bool isIncognitoMode;          // Normal vs incognito
  final String? normalModeActiveTabId; // Preserved when switching to incognito
  final String? incognitoModeActiveTabId;
  final List<String> loadedResources;  // URLs of resources loaded on active page
}
```

### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `AddTabEvent` | `url?`, `isIncognito` | Create a new tab, optionally with a URL |
| `RemoveTabEvent` | `tabId` | Close a tab |
| `SelectTabEvent` | `tabId` | Switch active tab |
| `UpdateTabEvent` | `tabId`, `title?`, `url?`, `progress?`, `thumbnail?` | Update tab metadata |
| `AddLoadedResourceEvent` | `url` | Record a resource URL loaded by the WebView |
| `ClearLoadedResourcesEvent` | — | Clear resource list (on navigation) |
| `ToggleIncognitoModeEvent` | — | Switch between normal/incognito |
| `LoadCachedTabsEvent` | — | Restore persisted tabs from SharedPreferences |

### Key Behaviors

- Adding a tab automatically selects it as active
- Removing the active tab selects the previous tab (or creates a blank one if none remain)
- Incognito tabs are never written to SharedPreferences
- `UpdateTabEvent` with only `progress` or `thumbnail` does not emit a new state if no other fields changed (prevents unnecessary rebuilds)
- Resource list is per-tab but only tracked for the active tab

---

## SearchBloc

**File:** `lib/features/search/bloc/search_bloc.dart`

### State: `SearchState`

```dart
class SearchState {
  final String query;
  final SearchEngine engine;
  final List<String> suggestions;
  final List<String> history;
  final List<String> trending;
  final bool isLoadingSuggestions;
}
```

### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `UpdateQueryEvent` | `query` | User typed in search bar |
| `SetEngineEvent` | `engine` | User changed search engine |
| `PerformSearchEvent` | `query` | User submitted search |
| `LoadHistoryEvent` | — | Load search history from storage |
| `ClearHistoryEvent` | — | Delete all search history |
| `DeleteHistoryItemEvent` | `query` | Remove single history entry |
| `LoadTrendingEvent` | — | Load trending searches for current engine |
| `LoadSuggestionsEvent` | `query` | Fetch autocomplete suggestions |

### Search History

- Stored in SharedPreferences under key `search_history`
- Max 50 entries (oldest removed on overflow)
- Deduplication: adding an existing query moves it to top

---

## MediaBloc

**File:** `lib/features/media/bloc/media_bloc.dart`

### State: `MediaState`

```dart
class MediaState {
  final List<MediaExtractResult> resources; // Filtered by active type
  final MediaResourceType activeFilter;      // All, Image, Video, Audio
  final bool isLoading;
}
```

### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `MediaExtractFromResources` | `List<String> urls` | Process raw URLs from TabBloc |
| `MediaRefreshRequested` | — | Re-filter current resource list |
| `MediaFilterChanged` | `MediaResourceType` | Switch gallery filter tab |

### Resource Classification

`MediaUtils.detectType(url)` returns `MediaType`:
- Checks file extension first
- Falls back to MIME type hint if available
- Skips `data:` and `blob:` scheme URLs
- Unknown types are excluded from the gallery

---

## DownloadBloc

**File:** `lib/features/download/bloc/download_bloc.dart`

### State: `DownloadState`

```dart
class DownloadState {
  final List<DownloadItem> downloads;  // All download items
  final int activeCount;               // Currently downloading (max 5)
}

class DownloadItem {
  final String id;
  final String url;
  final String filename;
  final DownloadStatus status;         // queued, downloading, paused, completed, failed
  final double progress;               // 0.0 to 1.0
  final int? totalBytes;
  final int? receivedBytes;
  final String? localPath;             // Set on completion
  final String? error;                 // Set on failure
}
```

### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `DownloadStartEvent` | `url`, `filename?` | Enqueue a download |
| `DownloadBatchStartEvent` | `List<String> urls` | Enqueue multiple downloads |
| `DownloadPauseEvent` | `id` | Pause an active download |
| `DownloadResumeEvent` | `id` | Resume a paused download |
| `DownloadCancelEvent` | `id` | Cancel and remove a download |
| `DownloadProgressEvent` | `id`, `progress`, `received`, `total` | Internal — progress update |
| `DownloadCompleteEvent` | `id`, `localPath` | Internal — download finished |
| `DownloadFailedEvent` | `id`, `error` | Internal — download failed |

### Concurrency

- Max 5 simultaneous downloads
- New downloads beyond the limit are queued (`DownloadStatus.queued`)
- When an active download completes/fails/is cancelled, the next queued item starts automatically

---

## ConnectivityBloc

**File:** `lib/core/services/connectivity/bloc/connectivity_bloc.dart`

### State: `ConnectivityState`

```dart
// Generated with Freezed
@freezed
class ConnectivityState with _$ConnectivityState {
  const factory ConnectivityState.connected() = Connected;
  const factory ConnectivityState.disconnected() = Disconnected;
  const factory ConnectivityState.unknown() = Unknown;
}
```

### Events

```dart
@freezed
class ConnectivityEvent with _$ConnectivityEvent {
  const factory ConnectivityEvent.check() = Check;
  const factory ConnectivityEvent.changed(ConnectivityResult result) = Changed;
}
```

### Usage in UI

```dart
BlocListener<ConnectivityBloc, ConnectivityState>(
  listener: (context, state) {
    state.when(
      connected: () => _onConnectionRestored(),
      disconnected: () => _showOfflinePage(),
      unknown: () {},
    );
  },
)
```

---

## BLoC Communication Patterns

### TabBloc → MediaBloc

`HomePage` listens to `TabBloc` and dispatches to `MediaBloc` when resources change:

```dart
BlocListener<TabBloc, TabState>(
  listenWhen: (prev, curr) => prev.loadedResources != curr.loadedResources,
  listener: (context, state) {
    context.read<MediaBloc>().add(
      MediaExtractFromResources(urls: state.loadedResources),
    );
  },
)
```

### WebViewPage → TabBloc

`WebViewPage` receives `TabBloc` indirectly via callbacks passed from `HomePage`:

```dart
// In HomePage
WebViewPage(
  onProgressChanged: (progress) =>
    context.read<TabBloc>().add(UpdateTabEvent(id: tabId, progress: progress)),
  onTitleChanged: (title) =>
    context.read<TabBloc>().add(UpdateTabEvent(id: tabId, title: title)),
  onResourceLoaded: (url) =>
    context.read<TabBloc>().add(AddLoadedResourceEvent(url: url)),
)
```

This keeps `WebViewPage` decoupled from BLoC — it communicates through callbacks, making it independently testable.
