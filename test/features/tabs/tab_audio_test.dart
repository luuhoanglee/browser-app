import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:browser_app/data/repositories/tab_repository_impl.dart';
import 'package:browser_app/features/tabs/bloc/tab_bloc.dart';
import 'package:browser_app/features/tabs/bloc/tab_event.dart';
import 'package:browser_app/features/tabs/bloc/tab_state.dart';

/// BLoC tests for issue #20 — single-audio-owner logic in [TabBloc].
///
/// The invariant under test: **at most one tab is ever unmuted**. `audioTabId`
/// names that tab; `TabState.isTabMuted` derives per-tab mute from it.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Builds a bloc and waits for _init (+ its background microtask) to settle.
  Future<TabBloc> newBloc() async {
    final bloc = TabBloc(TabRepositoryImpl());
    await Future.delayed(const Duration(milliseconds: 30));
    return bloc;
  }

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 20));

  int unmutedCount(TabState s) =>
      s.tabs.where((t) => !s.isTabMuted(t.id)).length;

  test('the active tab owns audio on startup', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);

    final active = bloc.state.activeTab!;
    expect(bloc.state.audioTabId, active.id);
    expect(bloc.state.isTabMuted(active.id), isFalse);
    expect(unmutedCount(bloc.state), 1);
  });

  test('a newly added tab takes over audio and mutes the old one', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);
    final firstId = bloc.state.activeTab!.id;

    bloc.add(AddTabEvent());
    await settle();

    expect(bloc.state.tabs.length, 2);
    final newId = bloc.state.activeTab!.id;
    expect(newId, isNot(firstId));
    expect(bloc.state.audioTabId, newId);
    expect(bloc.state.isTabMuted(firstId), isTrue);
    expect(bloc.state.isTabMuted(newId), isFalse);
    expect(unmutedCount(bloc.state), 1);
  });

  test(
    'SetAudioTabEvent moves sound to another pane, muting the rest',
    () async {
      final bloc = await newBloc();
      addTearDown(bloc.close);
      final firstId = bloc.state.activeTab!.id;
      bloc.add(AddTabEvent());
      await settle();
      final newId = bloc.state.activeTab!.id;

      // Give audio back to the first tab.
      bloc.add(SetAudioTabEvent(firstId));
      await settle();

      expect(bloc.state.audioTabId, firstId);
      expect(bloc.state.isTabMuted(firstId), isFalse);
      expect(bloc.state.isTabMuted(newId), isTrue);
      expect(unmutedCount(bloc.state), 1, reason: 'at most one pane has sound');
    },
  );

  test('tapping the current audio pane mutes everything', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);
    bloc.add(AddTabEvent());
    await settle();
    final ownerId = bloc.state.audioTabId!;

    // Toggle the owner off.
    bloc.add(SetAudioTabEvent(ownerId));
    await settle();

    expect(bloc.state.audioTabId, isNull);
    expect(unmutedCount(bloc.state), 0, reason: 'every pane muted');
  });

  test('switching tabs moves audio to the focused tab', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);
    final firstId = bloc.state.activeTab!.id;
    bloc.add(AddTabEvent());
    await settle();

    bloc.add(SelectTabEvent(firstId));
    await settle();

    expect(bloc.state.activeTab!.id, firstId);
    expect(bloc.state.audioTabId, firstId);
    expect(unmutedCount(bloc.state), 1);
  });

  test('SetAudioTabEvent for an unknown tab is ignored', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);
    final before = bloc.state.audioTabId;

    bloc.add(SetAudioTabEvent('no-such-tab'));
    await settle();

    expect(bloc.state.audioTabId, before);
  });

  test('closing a non-audio tab keeps the audio owner intact', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);
    final firstId = bloc.state.activeTab!.id;
    bloc.add(AddTabEvent());
    await settle();
    final secondId = bloc.state.activeTab!.id;

    // Give audio to the (non-active) first tab.
    bloc.add(SetAudioTabEvent(firstId));
    await settle();
    expect(bloc.state.audioTabId, firstId);

    // Close the active tab (which does NOT own audio).
    bloc.add(RemoveTabEvent(secondId));
    await settle();

    expect(bloc.state.tabs.any((t) => t.id == secondId), isFalse);
    // The surviving audio owner keeps its sound; still at most one unmuted.
    expect(bloc.state.audioTabId, firstId);
    expect(bloc.state.isTabMuted(firstId), isFalse);
    expect(unmutedCount(bloc.state), 1);
  });

  test('closing the active audio tab leaves no pane holding sound', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);
    bloc.add(AddTabEvent());
    await settle();
    final activeAudioId = bloc.state.audioTabId!; // the active, sounding tab

    bloc.add(RemoveTabEvent(activeAudioId));
    await settle();

    // The app does not auto-focus another tab, so audio ownership clears.
    expect(bloc.state.tabs.any((t) => t.id == activeAudioId), isFalse);
    expect(bloc.state.audioTabId, isNull);
    expect(unmutedCount(bloc.state), 0);
  });
}
