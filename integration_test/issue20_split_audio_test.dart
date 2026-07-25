import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:browser_app/data/repositories/tab_repository_impl.dart';
import 'package:browser_app/features/tabs/bloc/tab_bloc.dart';
import 'package:browser_app/features/tabs/bloc/tab_event.dart';
import 'package:browser_app/features/tabs/bloc/tab_state.dart';
import 'package:browser_app/presentation/pages/home/widgets/split_audio_toggle.dart';

/// E2E (integration) coverage for issue #20.
///
/// Drives the real [TabBloc] audio logic through the real [SplitAudioToggle]
/// widget in a two-pane layout that mirrors split view: each pane renders its
/// picture regardless of mute state, and only the pane whose toggle is "on"
/// keeps sound. The whole flow enforces "at most one pane has audio".
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget twoPaneApp(TabBloc bloc) {
    return MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: Scaffold(
          body: BlocBuilder<TabBloc, TabState>(
            builder: (context, state) => Column(
              children: [
                for (final tab in state.tabs)
                  Expanded(
                    child: Container(
                      key: ValueKey('pane_${tab.id}'),
                      color: Colors.black,
                      child: Stack(
                        children: [
                          // "Video picture" is always shown for every pane.
                          Center(
                            child: Text(
                              state.isTabMuted(tab.id) ? 'MUTED' : 'SOUND',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: SplitAudioToggle(
                              muted: state.isTabMuted(tab.id),
                              onToggle: () => context.read<TabBloc>().add(
                                SetAudioTabEvent(tab.id),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('at most one split pane has sound across toggles', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final bloc = TabBloc(TabRepositoryImpl());
    addTearDown(bloc.close);
    await tester.pump(const Duration(milliseconds: 40)); // let _init settle

    final firstId = bloc.state.activeTab!.id;
    bloc.add(AddTabEvent());
    await tester.pump(const Duration(milliseconds: 40));
    final secondId = bloc.state.activeTab!.id;

    await tester.pumpWidget(twoPaneApp(bloc));
    await tester.pumpAndSettle();

    // Both panes show their picture; exactly one has sound (the new/active one).
    expect(find.byType(SplitAudioToggle), findsNWidgets(2));
    expect(find.text('SOUND'), findsOneWidget);
    expect(find.text('MUTED'), findsOneWidget);
    expect(
      tester.widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey('pane_$secondId')),
          matching: find.text('SOUND'),
        ),
      ),
      isNotNull,
    );

    // Tap the first pane's toggle → sound moves there, other pane mutes.
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey('pane_$firstId')),
        matching: find.byType(SplitAudioToggle),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SOUND'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(ValueKey('pane_$firstId')),
        matching: find.text('SOUND'),
      ),
      findsOneWidget,
    );

    // Tap the same pane again → everything muted (audio owner toggled off).
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey('pane_$firstId')),
        matching: find.byType(SplitAudioToggle),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SOUND'), findsNothing);
    expect(find.text('MUTED'), findsNWidgets(2));
  });
}
