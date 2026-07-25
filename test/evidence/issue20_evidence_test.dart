import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:browser_app/presentation/pages/home/widgets/split_audio_toggle.dart';

/// Renders before/after PNG evidence for issue #20 at widget level.
///
/// Not an assertion test — run with `flutter test test/evidence` to (re)generate
/// the images under docs/evidence/v1.0.3/issue-20/. The panes are placeholders
/// (a real WebView can't render headless); the *after* frame uses the real
/// [SplitAudioToggle]. Actual audio behaviour is verified by the bloc /
/// integration tests. Glyphs use the headless test font.
void main() {
  const size = Size(411, 914);
  const dir = 'docs/evidence/v1.0.3/issue-20';

  Widget pane({
    required Color accent,
    required bool playing,
    required String caption,
    Widget? overlay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        border: Border.all(color: accent, width: 1),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  playing ? Icons.play_circle_fill : Icons.pause_circle_filled,
                  size: 64,
                  color: playing ? Colors.white : Colors.white24,
                ),
                const SizedBox(height: 12),
                Text(
                  caption,
                  style: TextStyle(
                    color: playing ? Colors.white70 : Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (overlay != null) Positioned(top: 8, right: 8, child: overlay),
        ],
      ),
    );
  }

  // MaterialApp provides the Overlay that SplitAudioToggle's Tooltip needs.
  Widget frame(GlobalKey key, {required Widget top, required Widget bottom}) =>
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                Expanded(child: top),
                Container(height: 4, color: Colors.black26),
                Expanded(child: bottom),
              ],
            ),
          ),
        ),
      );

  Future<void> capture(WidgetTester tester, GlobalKey key, String file) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(dir).createSync(recursive: true);
      File('$dir/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('generate issue #20 before/after evidence', (tester) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // BEFORE: only one pane can play — the second grabs audio focus, so the
    // first (or second) pauses. No way to keep both playing.
    final beforeKey = GlobalKey();
    await tester.pumpWidget(
      frame(
        beforeKey,
        top: pane(
          accent: Colors.blue,
          playing: true,
          caption: 'Pane 1 · đang phát (có tiếng)',
        ),
        bottom: pane(
          accent: Colors.orange,
          playing: false,
          caption: 'Pane 2 · TỰ DỪNG (mất audio focus)',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, beforeKey, 'issue-20-before.png');

    // AFTER: both panes keep playing; a per-pane toggle picks which one is
    // audible. The muted pane never grabs audio focus.
    final afterKey = GlobalKey();
    await tester.pumpWidget(
      frame(
        afterKey,
        top: pane(
          accent: Colors.blue,
          playing: true,
          caption: 'Pane 1 · đang phát · CÓ TIẾNG',
          overlay: SplitAudioToggle(muted: false, onToggle: () {}),
        ),
        bottom: pane(
          accent: Colors.orange,
          playing: true,
          caption: 'Pane 2 · đang phát · đã tắt tiếng',
          overlay: SplitAudioToggle(muted: true, onToggle: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, afterKey, 'issue-20-after.png');

    expect(File('$dir/issue-20-before.png').existsSync(), isTrue);
    expect(File('$dir/issue-20-after.png').existsSync(), isTrue);
  });
}
