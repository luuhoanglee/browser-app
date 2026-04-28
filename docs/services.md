# Services & Utilities

## Core Services

### FirebaseService

**File:** `lib/core/services/fcm/firebase_service.dart`

Initializes all Firebase products at app startup:

```dart
await FirebaseService.initialize();
```

Responsibilities:
- `Firebase.initializeApp()` with platform options
- `FirebaseCrashlytics` — sets `recordError` as the Flutter error handler
- `FirebaseMessaging` — requests notification permissions, retrieves and caches FCM token
- `FirebaseAnalytics` — enables analytics collection
- Background message handler registration

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

### Logger

**File:** `lib/core/logger/logger.dart`

Custom structured logger with configurable log levels. Output format includes timestamp, level, and tag.

```dart
AppLogger.debug('WebView', 'Page loaded: $url');
AppLogger.error('Download', 'Failed: $error', stackTrace);
```

Log levels: `debug`, `info`, `warning`, `error`.

### ValidateData

**File:** `lib/core/utils/validate_data.dart`

Input validation utilities:
- `isValidUrl(string)` — checks if string is a valid URL
- `isSearchQuery(string)` — returns true if input should be treated as search
- `sanitizeUrl(string)` — ensures URL has protocol prefix
