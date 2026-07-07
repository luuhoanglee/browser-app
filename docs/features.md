# Features

## Tab Management

Handled by `TabBloc` (`lib/features/tabs/bloc/tab_bloc.dart`).

### Normal Tabs

- Create new tabs (blank or with URL)
- Switch between tabs — active tab preserved in state
- Close individual tabs or all tabs
- Thumbnail preview captured on page load stop
- Tab title and URL updated in real time as page loads

### Incognito Mode

- Toggle via `ToggleIncognitoModeEvent`
- Incognito and normal tabs are stored separately; switching modes restores the previous active tab for that mode
- Incognito tabs are **never** persisted to SharedPreferences
- History, cookies, and cache are not saved for incognito sessions
- Visual indicator distinguishes incognito from normal tabs

### Tab Persistence

- Non-incognito tabs saved to SharedPreferences via `StorageService`
- Writes are debounced (2 seconds) to reduce I/O
- On app start, cached tabs are restored and validated (invalid `intent://` URLs are filtered out)
- Thumbnails stored as base64 strings

---

## WebView

Implemented in `lib/features/webview/widgets/webview_page.dart` using a local fork of `flutter_inappwebview`.

### Navigation

- Load URLs and search queries
- Back / forward via WebView history
- Custom dual-layer navigation history preserves state across tab switches
- Swipe left/right gesture for back/forward
- Pull-to-refresh reloads current page

### Content Interception

`WebViewInterceptor` (`lib/features/webview/services/webview_interceptor.dart`) intercepts all network requests:

- Blocks requests matching domain blocklist (`blockerList.json`)
- Blocks URLs matching pattern list (`block_ad_pattern.txt`)
- Blocks popup windows
- Handles `intent://` scheme URLs (converts to HTTPS or opens external app)
- Handles custom URL schemes (opens external apps with user confirmation)

### JavaScript Injection

Scripts injected on page load:

| Script | Purpose |
|--------|---------|
| Anti-detect script | Disables console output, masks `navigator` properties |
| Intent URL blocker | Intercepts `intent://` links before navigation |
| YouTube ad blocker | 280+ lines blocking ads at network, cosmetic, and player levels |
| General ad blocker | Hides ad elements by CSS selector |

### Error Handling

Custom error pages for:
- Network unavailable (offline detection via `ConnectivityBloc`)
- SSL errors
- HTTP errors (404, 5xx)
- Request timeout
- Page crash / rendering failure

### iOS vs Android Differences

- iOS: uses `WKContentRuleList` via `IOSContentBlockerService` for native content blocking
- Android: uses request interception via `shouldOverrideUrlLoading` / `shouldInterceptRequest`
- Media playback inline enabled on both platforms

---

## Ad Blocking

Multi-layer approach:

### Layer 1 — Domain Blocklist

`ContentBlockerService` (`lib/features/webview/services/content_blocker_service.dart`) loads `assets/blockerList.json` containing 100+ ad/tracker domains. Requests to these domains are blocked at the network level before loading.

Whitelisted CDNs are excluded to avoid breaking legitimate content.

### Layer 2 — URL Pattern Matching

`AdPatternLoader` loads `assets/block_ad_pattern.txt` with URL patterns (regex). Any request URL matching these patterns is blocked.

### Layer 3 — YouTube Ad Blocker

Injected JavaScript manipulates the YouTube player response to:
- Remove ad slots from player config
- Block ad network requests (googlevideo, doubleclick, etc.)
- Hide ad UI elements via CSS
- Skip any ads that still load

### Layer 4 — iOS Native Rules

On iOS, content rules are compiled to `WKContentRuleList` format for native-level blocking with zero performance overhead.

---

## Search

Handled by `SearchBloc` (`lib/features/search/bloc/search_bloc.dart`).

### Search Engines

| Engine | Query URL |
|--------|-----------|
| Google | `google.com/search?q=` |
| Bing | `bing.com/search?q=` |
| DuckDuckGo | `duckduckgo.com/?q=` |
| YouTube | `youtube.com/search?q=` |

Engine selection persisted to SharedPreferences.

### Smart URL Detection

Input is classified as:
- **URL** — if it matches URL pattern (has protocol, TLD, etc.) → loaded directly
- **Search query** — otherwise → formatted with selected engine's query URL

### Suggestions

- Fetched from `SearchService` as user types
- Debounced to avoid excessive API calls
- Displayed in `SearchPage` dropdown

### Search History

- Up to 50 most recent searches stored
- Displayed as quick suggestions when search bar is focused
- Individual items can be deleted
- Full history clearable

### Trending Searches

- Loaded per search engine on `SearchPage` open
- Displayed when search bar is empty

---

## Media Gallery

Handled by `MediaBloc` (`lib/features/media/bloc/media_bloc.dart`).

### Resource Collection

Every resource loaded by the WebView triggers `AddLoadedResourceEvent`. Resources are classified by `MediaUtils` based on URL patterns and MIME types:

| Type | Detection |
|------|----------|
| Image | `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.svg`, image MIME |
| Video | `.mp4`, `.webm`, `.m3u8`, `.mkv`, video MIME |
| Audio | `.mp3`, `.aac`, `.ogg`, `.wav`, audio MIME |

`data:` and `blob:` URLs are excluded.

### Media Viewers

| Type | Viewer |
|------|--------|
| Image | `ImageViewerPage` using `photo_view` (pinch-to-zoom, swipe) |
| Video | `VideoPlayerPage` using `video_player` + `chewie` |
| Audio | `AudioPlayerPage` using `just_audio` with background playback |

### Gallery UI

`MediaGallerySheet` displays resources in a filterable grid:
- Filter tabs: All, Images, Videos, Audio
- Tap to open viewer
- Long press for download option

---

## Downloads

Handled by `DownloadBloc` (`lib/features/download/bloc/download_bloc.dart`).

### Capabilities

- Download any file (detected from URL or WebView context menu)
- Maximum 5 concurrent downloads (configurable)
- Queue: additional downloads wait until a slot is free
- Pause and resume individual downloads
- Cancel downloads
- Batch download (download multiple files at once, queued)

### Implementation

`DownloadService` (`lib/data/services/download_service.dart`) uses Dio with:
- `CancelToken` for cancellation
- `onReceiveProgress` callback for progress tracking
- Chunked reception for large files

### Foreground Service

`ForegroundDownloadService` runs as an Android foreground service to keep downloads alive when the app is backgrounded. A persistent notification shows current download progress.

### Notifications

`DownloadNotificationService` posts:
- Progress notifications (updated as download proceeds)
- Completion notification with "Open" action
- Failure notification with error message

### Download Sheet

`DownloadSheet` widget shows:
- Active downloads with progress bars
- Pause/resume/cancel controls
- Completed downloads with open/share options
- Failed downloads with retry option

---

## Deep Linking

Configured for HTTP/HTTPS URLs in `AndroidManifest.xml`.

### Flow

1. External app (email, messaging) taps a link
2. Android routes to `MainActivity` (singleTop)
3. Native code sends URL via `MethodChannel` (`com.dino.pardix/deeplink`)
4. `main.dart` receives URL and calls `_loadDeepLinkUrl()`
5. `HomePage` opens the URL in the active tab or a new tab

### App Links

`app_links` package handles links when app is already running in background.

---

## Offline Mode

`ConnectivityBloc` (`lib/core/services/connectivity/bloc/connectivity_bloc.dart`) monitors network state via `connectivity_plus`.

- State changes broadcast to all widgets via `BlocListener`
- WebView shows custom offline error page when connection lost
- Automatic reload attempted when connection restored
- Toolbar and URL bar reflect offline state

---

## Firebase Integration

| Service | Usage |
|---------|-------|
| Firebase Core | Initialization |
| Firebase Crashlytics | Automatic crash reporting, `runZonedGuarded` wrapper |
| Firebase Messaging | FCM push notifications, background message handler |
| Firebase Analytics | Event tracking |

FCM token is cached in SharedPreferences and refreshed on each launch.
