# Issue #21 — Scroll hides bottom bar and leaves a white band at the bottom

## Root cause

When the toolbar hides on scroll, the home page swaps `BottomBarWrapper` for
`MiniUrlBarWrapper`. `MiniUrlBar` wrapped its content in `SafeArea(bottom: false)`,
which leaves `top: true` (the default). At the **bottom** of the screen that
injects a **status-bar-height top inset** above the pill. Because the mini bar is
transparent, that inset exposes the white `Scaffold` background, producing the
tall white band reported in the issue (only the small URL pill remains, with
blank space above it).

## Fix

`lib/presentation/pages/home/widgets/mini_url_bar.dart` — the bottom-anchored bar
now uses `SafeArea(top: false)`, so it ignores the status-bar inset and instead
respects the bottom gesture-nav inset. The bar hugs the pill; page content fills
right down to it. Background stays transparent (no hard-coded white), so it also
matches the dark Scaffold in incognito.

## Before / After

| Before (bug) | After (fix) |
|---|---|
| ![before](issue-21-before.png) | ![after](issue-21-after.png) |

Widget-level renders on a Pixel-class profile (411×914, top inset 47, bottom
gesture inset 34). Glyphs use the headless test font — the relevant signal is the
layout: the **before** frame shows the wide white band between the dark page and
the pill; the **after** frame has the page content reaching the pill, which sits
just above the gesture-nav inset. Regenerate with:

```bash
flutter test test/evidence/issue21_evidence_test.dart -d flutter-tester
```

## Tests

- `test/presentation/home/home_ui_cubit_test.dart` — Cubit test: toolbar
  hide/show + reset transitions that drive the mini-bar swap (6 cases).
- `test/presentation/home/mini_url_bar_test.dart` — widget test: the top
  status-bar inset is not applied, the bottom gesture inset is respected, and
  `SafeArea` is configured `top:false/bottom:true` (3 cases).
- `integration_test/issue21_bottom_bar_test.dart` — E2E: hiding the toolbar
  leaves no white band; page content is flush to the mini bar and the pill
  respects the bottom inset (1 case).

All pass headless via `flutter test … -d flutter-tester`. The E2E test was **also
run on a real Android emulator** (Android 15 / API 35, `emulator-5554`) — see
[`android-integration-test.log`](android-integration-test.log):

```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
00:24 +1: All tests passed!
```
