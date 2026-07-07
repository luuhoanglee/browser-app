# Services & Utilities

## Core Services

### FirebaseService

**File:** `lib/core/services/fcm/firebase_service.dart`

Initializes all Firebase products at app startup:

```dart
await FirebaseService.initializeFirebase();
```

Responsibilities:
- `Firebase.initializeApp()`
- `FirebaseCrashlytics` — wires `FlutterError.onError` and `PlatformDispatcher.instance.onError` to `AppLogger.fatal()`; collection enabled in release only
- `AppLogger.initFirebase()` — connects logger to Firebase after init
- `FirebaseMessaging` — requests notification permissions, retrieves and caches FCM token
- `FirebaseAnalytics` — Analytics instance available via `AppLogger.event()`
- Local notification channel registration

FCM token is cached in SharedPreferences. Refreshed on each app start.

---

### ConnectivityService

**File:** `lib/core/services/connectivity/connectivity_service.dart`

Wraps `connectivity_plus` and exposes a `Stream<ConnectivityResult>` consumed by `ConnectivityBloc`.

```dart
ConnectivityService.stream   // Stream<ConnectivityResult>
ConnectivityService.current  // Future<ConnectivityResult>
```

---

### LocalNotificationService

**File:** `lib/core/services/local_notification_service.dart`

Wraps `flutter_local_notifications`. Used by `DownloadNotificationService` to post download progress and completion notifications.

```dart
await LocalNotificationService.initialize();
await LocalNotificationService.show(id, title, body, payload);
await LocalNotificationService.update(id, title, body, progress, maxProgress);
await LocalNotificationService.cancel(id);
```

Notification channels configured:
- `download_channel` — download progress (ongoing, low importance)
- `download_complete_channel` — completion (default importance, with actions)

---

### ForegroundDownloadService

**File:** `lib/core/services/foreground_download_service.dart`

Starts/stops the Android foreground service via `flutter_background` package. Required on Android 8+ to keep downloads alive when the app moves to background.

```dart
await ForegroundDownloadService.start();
await ForegroundDownloadService.stop();
```

The service is started when the first download begins and stopped when all downloads complete or are cancelled.

---

### OxoDbService

**File:** `lib/core/services/oxodb_service.dart`

API service for the OxoDB website analysis backend. Sends page URLs for analysis and returns metadata. Used for trending content and page insights.

---

### LocaleService

**File:** `lib/core/services/locale/locale_service.dart`

Manages app locale. Persists selected locale to SharedPreferences. Exposes via `LocaleCubit`.

---

## Data Services

### StorageService

**File:** `lib/data/services/storage_service.dart`

Persists tab state and browsing history using SharedPreferences.

| Method | Key | Description |
|--------|-----|-------------|
| `saveTabs(tabs)` | `cached_tabs` | Serialize tabs to JSON |
| `loadTabs()` | `cached_tabs` | Deserialize and return tab list |
| `saveHistory(history)` | `browse_history` | Save URL history |
| `loadHistory()` | `browse_history` | Load URL history |

**Debouncing:** `saveTabs()` is debounced with a 2-second window. Rapid tab updates (progress, title) do not cause excessive disk writes.

**Thumbnail storage:** Thumbnails are base64-encoded and stored inline. This can cause large preference files with many tabs — consider moving thumbnails to the filesystem for better performance.

---

### DownloadService

**File:** `lib/data/services/download_service.dart`

Dio-based file downloader.

```dart
final service = DownloadService();

// Start download
await service.download(
  url: 'https://example.com/file.pdf',
  savePath: '/storage/emulated/0/Download/file.pdf',
  onProgress: (received, total) { ... },
  cancelToken: cancelToken,
);

// Pause (cancel current request, keep partial file)
cancelToken.cancel();

// Resume (send Range header with received bytes)
await service.download(url: url, savePath: path, startByte: received, ...);
```

Pause/resume is implemented by:
1. Cancelling the Dio request on pause
2. Recording bytes received
3. Sending `Range: bytes=N-` header on resume

---

### DownloadNotificationService

**File:** `lib/data/services/download_notification_service.dart`

Coordinates with `LocalNotificationService` to show download progress. Each download gets a unique notification ID derived from its download ID.

---

## WebView Services

### ContentBlockerService

**File:** `lib/features/webview/services/content_blocker_service.dart`

Loads `assets/blockerList.json` — a list of ad/tracker domains. Used by the WebView interceptor to block requests before they are made.

Provides a whitelist of CDN domains that should never be blocked (to avoid breaking legitimate content).

---

### IOSContentBlockerService

**File:** `lib/features/webview/services/ios_content_blocker_service.dart`

Compiles domain and URL pattern blocklists into `WKContentRuleList` format for iOS native content blocking. This approach has zero performance overhead compared to JavaScript-based blocking.

---

### AdPatternLoader

**File:** `lib/features/webview/services/ad_pattern_loader.dart`

Loads `assets/block_ad_pattern.txt` — a list of URL regex patterns for ad blocking. Patterns are compiled once and reused across all WebView requests.

---

### WebViewInterceptor

**File:** `lib/features/webview/services/webview_interceptor.dart`

Intercepts all WebView network requests. Decision tree per request:

```
Request URL received
  ├── Matches blocked domain? → Block
  ├── Matches ad pattern? → Block
  ├── Is intent:// scheme? → Convert to HTTPS or open external app
  ├── Is custom scheme (tel:, mailto:, etc.)? → Open external app with dialog
  └── Otherwise → Allow
```

---

## Core Utilities

### Debouncer

**File:** `lib/core/utils/debouncer.dart`

General-purpose debounce utility used throughout the app.

```dart
final _debouncer = Debouncer(milliseconds: 2000);
_debouncer.run(() => _saveToStorage());
```

### MediaUtils

**File:** `lib/core/utils/media_utils.dart`

Classifies URLs by media type:

```dart
MediaUtils.detectType('https://cdn.example.com/image.jpg') // MediaType.image
MediaUtils.detectType('https://stream.example.com/video.mp4') // MediaType.video
MediaUtils.detectType('https://audio.example.com/track.mp3') // MediaType.audio
MediaUtils.detectType('https://example.com/page') // MediaType.unknown
```

Detection priority:
1. File extension
2. URL path patterns (e.g., `/stream/`, `/media/`)
3. Returns `unknown` if no match

### ApiClient

**File:** `lib/core/api/api_client.dart`

Dio instance configured with:
- `AuthInterceptor` — attaches auth headers
- `ErrorInterceptor` — maps HTTP errors to typed exceptions
- `ResponseInterceptor` — unwraps response envelope
- `LogInterceptor` — curl-style request logging in debug mode
- Default timeout: connect 30s, receive 60s

### AppLogger

**Files:**
- `lib/core/logger/app_logger.dart` — core logger (use this)
- `lib/core/logger/log_level.dart` — `LogLevel` enum
- `lib/core/logger/log_record.dart` — structured log entry model
- `lib/core/logger/analytics_event.dart` — Firebase Analytics event/param constants
- `lib/core/logger/logger.dart` — legacy wrapper (`@Deprecated`, kept for backward compat)

#### Log Levels

| Level | Emoji | Debug build | Release build |
|-------|-------|-------------|---------------|
| `VERBOSE` | 🔍 | Console only | Suppressed |
| `DEBUG` | 🐛 | Console only | Suppressed |
| `INFO` | 💡 | Console only | Crashlytics breadcrumb |
| `WARNING` | ⚠️ | Console | Crashlytics breadcrumb + non-fatal (if error attached) |
| `ERROR` | 🔴 | Console | Crashlytics non-fatal |
| `FATAL` | 💀 | Console | Crashlytics fatal |

`AppLogger.event()` always logs to Firebase Analytics in release builds.

#### Initialization

`AppLogger.initFirebase()` must be called after `Firebase.initializeApp()`. This is done automatically inside `FirebaseService.initializeFirebase()` — no manual call needed.

#### API

```dart
// ── Log levels ─────────────────────────────────────────────────
AppLogger.verbose('Tag', 'Granular trace message');
AppLogger.debug('Tag', 'Debug info: $value');
AppLogger.info('Tag', 'Notable event', params: {'key': 'value'});
AppLogger.warning('Tag', 'Unexpected but recoverable', error: e);
AppLogger.error('Tag', 'Caught exception', error: e, stackTrace: s);
AppLogger.fatal('Tag', 'Unrecoverable failure', error: e, stackTrace: s);

// ── Firebase Analytics event ───────────────────────────────────
AppLogger.event(AnalyticsEvent.searchPerformed, params: {
  AnalyticsParam.engine: 'google',
  AnalyticsParam.queryLength: query.length,
});

AppLogger.event(AnalyticsEvent.tabOpened, params: {
  AnalyticsParam.isIncognito: false,
  AnalyticsParam.tabCount: tabs.length,
});

AppLogger.event(AnalyticsEvent.downloadStarted, params: {
  AnalyticsParam.fileType: 'pdf',
  AnalyticsParam.fileSizeKb: 2048,
});
```

#### Tag Convention

Use the class or feature name as tag. This makes logs filterable in Logcat / IDE:

| Context | Tag |
|---------|-----|
| `TabBloc` | `'TabBloc'` |
| `WebViewPage` | `'WebView'` |
| `DownloadBloc` | `'Download'` |
| `SearchBloc` | `'Search'` |
| `FirebaseService` | `'FirebaseService'` |
| `StorageService` | `'Storage'` |

#### Analytics Events (`AnalyticsEvent`)

Constants defined in `lib/core/logger/analytics_event.dart`:

| Constant | Event name | When to fire |
|----------|------------|-------------|
| `tabOpened` | `tab_opened` | New tab created |
| `tabClosed` | `tab_closed` | Tab removed |
| `tabSwitched` | `tab_switched` | Active tab changed |
| `incognitoToggled` | `incognito_toggled` | Mode switched |
| `pageLoaded` | `page_loaded` | WebView `onLoadStop` |
| `pageLoadError` | `page_load_error` | WebView error |
| `deepLinkOpened` | `deep_link_opened` | External URL received |
| `searchPerformed` | `search_performed` | User submits search |
| `searchEngineChanged` | `search_engine_changed` | Engine changed |
| `downloadStarted` | `download_started` | Download enqueued |
| `downloadCompleted` | `download_completed` | Download finished |
| `downloadFailed` | `download_failed` | Download error |
| `mediaGalleryOpened` | `media_gallery_opened` | Gallery sheet opened |
| `mediaViewed` | `media_viewed` | Image/video/audio opened |
| `adBlocked` | `ad_blocked` | Request blocked |
| `notificationReceived` | `notification_received` | FCM message arrived |
| `notificationTapped` | `notification_tapped` | User taps notification |

#### Analytics Params (`AnalyticsParam`)

Common parameter keys:

```dart
AnalyticsParam.isIncognito   // bool
AnalyticsParam.tabCount      // int
AnalyticsParam.domain        // String
AnalyticsParam.errorType     // String
AnalyticsParam.engine        // String — 'google' | 'bing' | 'duckduckgo' | 'youtube'
AnalyticsParam.queryLength   // int
AnalyticsParam.fileType      // String — file extension
AnalyticsParam.fileSizeKb    // int
AnalyticsParam.mediaType     // String — 'image' | 'video' | 'audio'
AnalyticsParam.blockedCount  // int
AnalyticsParam.blockReason   // String — 'domain' | 'pattern' | 'youtube'
```

#### Flutter & Platform Error Wiring

`FirebaseService._initializeCrashlytics()` wires two global handlers:

```dart
// Flutter framework errors (rendering, widget tree)
FlutterError.onError → AppLogger.fatal(...)

// Dart/platform errors outside Flutter framework
PlatformDispatcher.instance.onError → AppLogger.fatal(...)
```

`main.dart` `runZonedGuarded` also routes zone errors to `AppLogger.fatal()`.

#### Migration from Legacy `Logger`

```dart
// Old — still works (deprecated)
Logger.show('message');
Logger.error(e, s);

// New — preferred
AppLogger.debug('MyClass', 'message');
AppLogger.error('MyClass', 'message', error: e, stackTrace: s);
```

### ValidateData

**File:** `lib/core/utils/validate_data.dart`

Input validation utilities:
- `isValidUrl(string)` — checks if string is a valid URL
- `isSearchQuery(string)` — returns true if input should be treated as search
- `sanitizeUrl(string)` — ensures URL has protocol prefix
