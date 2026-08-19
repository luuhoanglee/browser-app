# Release QA

Use this checklist for every release candidate. Device tests are tagged
`device` and intentionally run outside the stable unit/widget CI job.

## Device matrix

| Platform | Minimum target | Evidence |
|---|---|---|
| Android 8 / API 26 | phone, 3-button navigation | screenshot + log |
| Android 10 / API 29 | phone, gesture navigation | screenshot + video |
| Android 13 / API 33 | phone/tablet | screenshot + log |
| Android 16 / API 36 | OPPO CPH2625 or equivalent | screenshot + video |
| iOS | latest supported simulator/device | screenshot + log |

## Required regression scenarios

- Rotate portrait/landscape 20 times with toolbar expanded and collapsed.
- Scroll until the mini URL pill appears; verify no blank bottom strip.
- Exercise both split panes, focused page tools and audio ownership.
- Enter/exit fullscreen video and play an HLS stream.
- Pause/resume a ranged download.
- Open 30 normal tabs and a media-heavy split view; record RAM before/after.
- Force-stop the process and verify normal tabs can be restored or discarded.
- Verify incognito tabs/history/bookmarks are absent after restart.

## Evidence template

Store evidence under `docs/evidence/<version>/<issue>/` and record:

```text
Issue/PR:
Commit:
Build version:
Device / OS:
Orientation / navigation mode:
Steps:
Expected:
Actual:
RAM baseline / peak / after cleanup:
Attachments (screenshot, video, log):
Result: PASS / FAIL
```

Never commit Firebase configuration, signing keys, tokens or device secrets.
