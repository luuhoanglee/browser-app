import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:browser_app/domain/entities/tab_entity.dart';
import 'package:browser_app/presentation/pages/home/widgets/mini_url_bar.dart';

/// Renders before/after PNG evidence for issue #21 at widget level.
///
/// Not an assertion test — run with `flutter test test/evidence` to (re)generate
/// the images under docs/evidence/v1.0.3/issue-21/. Glyphs use the headless test
/// font; the point of the capture is the *layout* (the blank band above the pill).
void main() {
  const tab = TabEntity(
    id: 'tab-1',
    url: 'https://javhd.free/watch',
    title: 'demo',
    index: 0,
  );

  const size = Size(411, 914); // Pixel-class logical resolution
  const padding = EdgeInsets.only(top: 47, bottom: 34); // notch + gesture nav
  const dir = 'docs/evidence/v1.0.3/issue-21';

  // Faithful replica of the PRE-FIX mini bar: SafeArea(bottom:false) keeps the
  // top status-bar inset, which pads the bar down and exposes the white
  // Scaffold background above the pill.
  Widget oldMiniBar() => Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  height: 28,
                  constraints: const BoxConstraints(maxWidth: 250),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: const Text(
                    'javhd.free',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget fakePage() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12131A), Color(0xFF222436)],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.play_circle_fill,
          size: 72,
          color: Colors.white24,
        ),
      );

  Widget frame(GlobalKey key, {required Widget toolbar}) => MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: 2,
          padding: padding,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            // Colors.white = the home Scaffold background that leaks through.
            child: ColoredBox(
              color: Colors.white,
              child: Column(
                children: [
                  Expanded(child: fakePage()),
                  toolbar,
                ],
              ),
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

  testWidgets('generate issue #21 before/after evidence', (tester) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final beforeKey = GlobalKey();
    await tester.pumpWidget(frame(beforeKey, toolbar: oldMiniBar()));
    await tester.pumpAndSettle();
    await capture(tester, beforeKey, 'issue-21-before.png');

    final afterKey = GlobalKey();
    await tester.pumpWidget(
      frame(
        afterKey,
        toolbar: MiniUrlBar(activeTab: tab, controller: null, onTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, afterKey, 'issue-21-after.png');

    expect(File('$dir/issue-21-before.png').existsSync(), isTrue);
    expect(File('$dir/issue-21-after.png').existsSync(), isTrue);
  });
}
