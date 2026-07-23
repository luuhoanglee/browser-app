import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:browser_app/presentation/pages/home/widgets/split_audio_toggle.dart';

/// Widget tests for the per-pane audio toggle (issue #20).
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('unmuted pane shows the volume-on icon', (tester) async {
    await tester.pumpWidget(
      host(SplitAudioToggle(muted: false, onToggle: () {})),
    );

    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
  });

  testWidgets('muted pane shows the volume-off icon', (tester) async {
    await tester.pumpWidget(
      host(SplitAudioToggle(muted: true, onToggle: () {})),
    );

    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
  });

  testWidgets('tapping the toggle fires onToggle', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(SplitAudioToggle(muted: true, onToggle: () => taps++)),
    );

    await tester.tap(find.byType(SplitAudioToggle));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('exposes an accessible label that reflects mute state', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(SplitAudioToggle(muted: false, onToggle: () {})),
    );
    // Unmuted → the action is to mute this pane.
    expect(find.bySemanticsLabel(RegExp('Tắt tiếng')), findsAtLeastNWidgets(1));

    await tester.pumpWidget(
      host(SplitAudioToggle(muted: true, onToggle: () {})),
    );
    // Muted → the action is to enable sound for this pane.
    expect(find.bySemanticsLabel(RegExp('Bật tiếng')), findsAtLeastNWidgets(1));
  });
}
