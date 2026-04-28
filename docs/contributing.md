# Contributing

## Branching Strategy

```
main          ← production releases only
develop       ← integration branch (PRs target here)
feature/*     ← new features
fix/*         ← bug fixes
hotfix/*      ← urgent production fixes (branch from main)
```

### Branch Naming

```
feature/tab-grouping
feature/incognito-tab
fix/download-resume-crash
hotfix/auth-token-expired
```

## Workflow

1. Branch from `develop`
2. Make changes
3. Open PR → `develop`
4. Pass code review
5. Merge (squash preferred for features, merge for hotfixes)

`develop` is merged to `main` for release.

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add batch download support
fix: resolve crash when closing last tab
refactor: extract MediaGallerySheet to separate file
chore: update firebase_core to 3.7.0
docs: update setup guide for Android 14
```

| Prefix | When to use |
|--------|------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring (no behavior change) |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Dependency updates, config changes |
| `docs` | Documentation only |

## Code Style

Enforce with `flutter_lints`. Run before committing:

```bash
flutter analyze
dart format lib/
```

### Dart Conventions

- File names: `snake_case.dart`
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Constants: `camelCase` (not SCREAMING_SNAKE)
- Private members: `_prefixWithUnderscore`

### BLoC Conventions

- One BLoC per feature
- Events are named `NounVerbEvent` (e.g., `TabAddEvent`, `DownloadStartEvent`)
- States use descriptive field names, not generic `data`/`result`
- Use `Equatable` on all events and states
- Use `Freezed` for states with multiple variants (sealed unions)

### Widget Conventions

- Extract reusable widgets to `widgets/` within their feature folder
- Prefer `StatelessWidget` + `BlocBuilder` over `StatefulWidget` where possible
- Keep `build()` methods readable — extract large subtrees to named methods or widgets
- Do not access `BlocProvider` in deeply nested widgets; pass values down or use `context.read` at the top

## Adding a New Feature

1. Create `lib/features/<feature_name>/` directory
2. Add BLoC:
   ```
   bloc/
   ├── feature_bloc.dart
   ├── feature_event.dart
   └── feature_state.dart
   ```
3. Add widgets to `widgets/`
4. Add services to `services/` (if needed)
5. Register BLoC in `home_page.dart` `MultiBlocProvider`
6. Write unit tests in `test/features/<feature_name>/`

## Testing

### Unit Tests (BLoC)

Use `bloc_test` package:

```dart
blocTest<TabBloc, TabState>(
  'adding a tab selects it as active',
  build: () => TabBloc(repository: MockTabRepository()),
  act: (bloc) => bloc.add(AddTabEvent()),
  expect: () => [
    isA<TabState>().having((s) => s.tabs.length, 'tabs count', 1),
  ],
);
```

### Widget Tests

```dart
testWidgets('shows download progress', (tester) async {
  await tester.pumpWidget(
    BlocProvider.value(
      value: mockDownloadBloc,
      child: const DownloadSheet(),
    ),
  );
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
});
```

### What to Test

| Priority | Target |
|----------|--------|
| High | BLoC event → state transitions |
| High | URL validation and classification (URL vs search query) |
| High | Media type detection (`MediaUtils`) |
| Medium | Repository implementations with mocked storage |
| Medium | Widget rendering for key states (loading, error, empty) |
| Low | End-to-end WebView flows (manual testing preferred) |

## Pull Request Checklist

Before opening a PR:

- [ ] `flutter analyze` passes with no errors
- [ ] `dart format lib/` applied
- [ ] Unit tests added or updated for changed logic
- [ ] No new hardcoded strings (use `AppStrings`)
- [ ] No new hardcoded colors (use `AppColors`)
- [ ] No `print()` statements (use `AppLogger`)
- [ ] `.key.properties`, `google-services.json`, and `*.jks` not staged
- [ ] `build_runner` re-run if Freezed files changed

## Security Guidelines

- Never log sensitive data (tokens, passwords, personal data)
- Never commit secrets, keys, or credentials
- Validate and sanitize all external input (deep links, URL bar input)
- Do not use `eval()` or construct JS dynamically from user input
- Report security vulnerabilities directly to the maintainers, not via public issues
