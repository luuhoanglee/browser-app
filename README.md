# Pardix Browser

A feature-rich mobile browser built with Flutter, supporting Android and iOS. Includes ad blocking, tab management, incognito mode, media extraction, and background downloads.

## Features

- **Multi-tab browsing** — open, switch, and close tabs with thumbnail previews
- **Incognito mode** — private browsing with no history or cache saved
- **Ad blocking** — multi-layer blocking (domain filters, JS injection, CSS cosmetic, YouTube-specific)
- **Media gallery** — extract and view images, videos, and audio from any page
- **Background downloads** — download files with pause/resume via foreground service
- **Search engines** — Google, Bing, DuckDuckGo, YouTube with suggestions and history
- **Deep linking** — open external URLs directly into the browser
- **Offline detection** — real-time connectivity monitoring with error pages
- **Swipe navigation** — gesture-based back/forward
- **Pull to refresh** — reload current page by pulling down

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| Language | Dart (SDK ^3.10.0) |
| State management | flutter_bloc ^8.1.6 |
| WebView | flutter_inappwebview (local fork) |
| HTTP client | Dio ^5.4.0 |
| Local storage | SharedPreferences ^2.2.2 |
| Firebase | Core, Crashlytics, Messaging, Analytics |
| Code generation | Freezed ^2.5.2 |

## Project Structure

```
browser_app/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── core/                        # Shared utilities, services, config
│   │   ├── api/                     # API client + interceptors
│   │   ├── config/                  # Constants, themes, deep links, flavor
│   │   ├── enum/                    # App-wide enums
│   │   ├── extentions/              # Dart extensions
│   │   ├── logger/                  # Custom logger
│   │   ├── mixin/                   # Reusable widget mixins
│   │   ├── resources/               # Colors, strings, sizes, assets
│   │   ├── services/                # Firebase, FCM, connectivity, notifications
│   │   ├── shared/                  # Cache manager
│   │   └── utils/                   # Debouncer, validators, media utils
│   ├── data/                        # Data layer
│   │   ├── models/                  # TabModel
│   │   ├── repositories/            # Repository implementations
│   │   └── services/                # DownloadService, StorageService
│   ├── domain/                      # Domain layer
│   │   ├── entities/                # TabEntity
│   │   ├── repositories/            # Abstract repository contracts
│   │   └── usecases/                # UseCase base classes
│   ├── features/                    # Feature modules
│   │   ├── download/                # Download management
│   │   ├── media/                   # Media extraction and playback
│   │   ├── search/                  # Search, suggestions, history
│   │   ├── tabs/                    # Tab management
│   │   └── webview/                 # WebView rendering and content blocking
│   └── presentation/
│       └── pages/home/              # Main UI (HomePage)
├── android/                         # Android project
├── ios/                             # iOS project
├── assets/
│   ├── blockerList.json             # Ad block domain list
│   ├── block_ad_pattern.txt         # URL pattern blocklist
│   └── logo/                        # App icons
├── packages/
│   └── flutter_inappwebview/        # Local fork of flutter_inappwebview
└── docs/                            # Extended documentation
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.10.0
- Android Studio / Xcode
- Firebase project configured (see [docs/setup.md](docs/setup.md))
- Java 17

### Setup

```bash
# Clone the repo
git clone <repo-url>
cd browser_app

# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```

### Signing (Android)

Create `android/.key.properties`:

```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=<path-to-keystore.jks>
```

> **Note:** Never commit `.key.properties` to version control.

## Documentation

| Document | Description |
|----------|-------------|
| [docs/architecture.md](docs/architecture.md) | Clean Architecture + BLoC patterns |
| [docs/features.md](docs/features.md) | Feature breakdown and flows |
| [docs/state-management.md](docs/state-management.md) | BLoC reference for all features |
| [docs/services.md](docs/services.md) | Core services and utilities |
| [docs/setup.md](docs/setup.md) | Full environment setup guide |
| [docs/contributing.md](docs/contributing.md) | Branching, conventions, code review |

## Android Permissions

| Permission | Reason |
|-----------|---------|
| `INTERNET` | Load web pages |
| `ACCESS_NETWORK_STATE` | Connectivity monitoring |
| `WRITE/READ_EXTERNAL_STORAGE` | File downloads (API ≤ 32) |
| `READ_MEDIA_IMAGES/VIDEO/AUDIO` | Media access (API 33+) |
| `FOREGROUND_SERVICE` | Background download service |
| `POST_NOTIFICATIONS` | Download progress notifications |

## Build Flavors

See [docs/setup.md#flavors](docs/setup.md#flavors) for flavor configuration.

## Contributing

See [docs/contributing.md](docs/contributing.md).
