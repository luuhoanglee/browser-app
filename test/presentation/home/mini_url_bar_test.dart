import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:browser_app/domain/entities/tab_entity.dart';
import 'package:browser_app/presentation/pages/home/widgets/mini_url_bar.dart';

/// Regression tests for issue #21.
///
/// The mini URL bar sits at the very bottom of the screen. It must NOT apply
/// the top (status bar) safe-area inset, which previously padded the bar
/// downward and left a tall blank strip above the pill exposing the white
/// Scaffold background.
void main() {
  const tab = TabEntity(
    id: 'tab-1',
    url: 'https://javhd.free/watch',
    title: 'demo',
    index: 0,
  );

  // Mirrors how the mini bar is laid out inside the home page: unbounded
  // vertical space (a Column child), so it hugs its intrinsic content height.
  Widget harness({required EdgeInsets viewPadding}) {
    return MediaQuery(
      data: MediaQueryData(padding: viewPadding),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MiniUrlBar(activeTab: tab, controller: null, onTap: _noop),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('does not apply the top status-bar inset', (tester) async {
    // A deliberately huge top inset — if it leaked into the layout the bar
    // would be ~244px tall instead of ~44px.
    await tester.pumpWidget(
      harness(viewPadding: const EdgeInsets.only(top: 200)),
    );

    final barHeight = tester.getSize(find.byType(MiniUrlBar)).height;
    expect(
      barHeight,
      lessThan(120),
      reason: 'top status-bar inset must not pad the bottom-anchored mini bar',
    );

    // The blank gap between the top of the bar and the pill must be tiny.
    final barTop = tester.getTopLeft(find.byType(MiniUrlBar)).dy;
    final pillTop = tester.getTopLeft(find.text('javhd.free')).dy;
    expect(pillTop - barTop, lessThan(40));
  });

  testWidgets('still respects the bottom gesture-nav inset', (tester) async {
    await tester.pumpWidget(
      harness(viewPadding: const EdgeInsets.only(bottom: 48)),
    );

    final bar = find.byType(MiniUrlBar);
    final barBottom = tester.getBottomLeft(bar).dy;
    final pillBottom = tester.getBottomLeft(find.text('javhd.free')).dy;

    // The pill is lifted above the gesture-nav area (~48px), not flush to the
    // physical screen edge.
    expect(barBottom - pillBottom, greaterThan(40));
  });

  testWidgets('SafeArea is configured for the bottom edge only', (tester) async {
    await tester.pumpWidget(harness(viewPadding: EdgeInsets.zero));

    final safeArea = tester.widget<SafeArea>(
      find.descendant(
        of: find.byType(MiniUrlBar),
        matching: find.byType(SafeArea),
      ),
    );
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isTrue);
  });
}

void _noop() {}
