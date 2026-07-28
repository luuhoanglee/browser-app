import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:browser_app/data/repositories/tab_repository_impl.dart';
import 'package:browser_app/features/tabs/bloc/tab_bloc.dart';
import 'package:browser_app/features/tabs/bloc/tab_event.dart';

/// BLoC tests for split-view pane focus.
///
/// The invariant under test: in split view exactly one of the two visible panes
/// is focused, and `TabState.focusedTabId` names it. Every toolbar control
/// (URL bar, back/forward, reload, progress, search, media) targets that id, so
/// both pages are operable — previously only the active/primary pane was.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<TabBloc> newBloc() async {
    final bloc = TabBloc(TabRepositoryImpl());
    await Future.delayed(const Duration(milliseconds: 30));
    return bloc;
  }

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 20));

  /// A bloc with two tabs in split view. Returns (primary, secondary) ids.
  Future<(TabBloc, String, String)> splitBloc() async {
    final bloc = await newBloc();
    final firstId = bloc.state.activeTab!.id;
    bloc.add(AddTabEvent());
    await settle();
    final secondId = bloc.state.activeTab!.id; // new tab becomes active
    bloc.add(EnableSplitViewEvent(firstId));
    await settle();
    // secondId is the active/primary pane, firstId the secondary pane.
    return (bloc, secondId, firstId);
  }

  test('outside split view the focused tab is just the active tab', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);

    expect(bloc.state.isSplitViewEnabled, isFalse);
    expect(bloc.state.focusedTabId, bloc.state.activeTab!.id);
  });

  test('enabling split focuses the primary pane', () async {
    final (bloc, primaryId, secondaryId) = await splitBloc();
    addTearDown(bloc.close);

    expect(bloc.state.isSplitViewEnabled, isTrue);
    expect(bloc.state.splitSecondaryTabId, secondaryId);
    expect(bloc.state.focusedTabId, primaryId);
    expect(bloc.state.isPaneFocused(primaryId), isTrue);
    expect(bloc.state.isPaneFocused(secondaryId), isFalse);
  });

  test('touching the secondary pane hands it the toolbar', () async {
    final (bloc, primaryId, secondaryId) = await splitBloc();
    addTearDown(bloc.close);

    bloc.add(FocusSplitPaneEvent(secondaryId));
    await settle();

    expect(bloc.state.focusedTabId, secondaryId);
    expect(bloc.state.focusedTab!.id, secondaryId);
    // The active tab is untouched — focus only moves the toolbar.
    expect(bloc.state.activeTab!.id, primaryId);
    expect(bloc.state.isPaneFocused(primaryId), isFalse);
  });

  test('focus can move back to the primary pane', () async {
    final (bloc, primaryId, secondaryId) = await splitBloc();
    addTearDown(bloc.close);

    bloc.add(FocusSplitPaneEvent(secondaryId));
    await settle();
    bloc.add(FocusSplitPaneEvent(primaryId));
    await settle();

    expect(bloc.state.focusedTabId, primaryId);
  });

  test('a tab that is not on screen cannot take focus', () async {
    final (bloc, primaryId, _) = await splitBloc();
    addTearDown(bloc.close);

    bloc.add(FocusSplitPaneEvent('no-such-tab'));
    await settle();

    expect(bloc.state.focusedTabId, primaryId);
  });

  test('focus is ignored while split view is off', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);
    final firstId = bloc.state.activeTab!.id;
    bloc.add(AddTabEvent());
    await settle();
    final secondId = bloc.state.activeTab!.id;

    bloc.add(FocusSplitPaneEvent(firstId));
    await settle();

    expect(bloc.state.focusedTabId, secondId, reason: 'still the active tab');
  });

  test('disabling split clears focus back to the active tab', () async {
    final (bloc, primaryId, secondaryId) = await splitBloc();
    addTearDown(bloc.close);

    bloc.add(FocusSplitPaneEvent(secondaryId));
    await settle();
    bloc.add(DisableSplitViewEvent());
    await settle();

    expect(bloc.state.isSplitViewEnabled, isFalse);
    expect(bloc.state.focusedPaneTabId, isNull);
    expect(bloc.state.focusedTabId, primaryId);
  });

  test('picking the secondary pane in the tab sheet swaps the panes', () async {
    final (bloc, primaryId, secondaryId) = await splitBloc();
    addTearDown(bloc.close);

    bloc.add(SelectTabEvent(secondaryId));
    await settle();

    // Same two pages stay on screen, roles swapped — no unrelated tab is
    // pulled into the split.
    expect(bloc.state.isSplitViewEnabled, isTrue);
    expect(bloc.state.activeTab!.id, secondaryId);
    expect(bloc.state.splitSecondaryTabId, primaryId);
    expect(bloc.state.focusedTabId, secondaryId);
  });

  test('choosing a new secondary pane points the toolbar at it', () async {
    final (bloc, primaryId, _) = await splitBloc();
    addTearDown(bloc.close);

    bloc.add(AddTabEvent()); // becomes active, split follows the new active tab
    await settle();
    final thirdId = bloc.state.activeTab!.id;
    bloc.add(SetSplitSecondaryTabEvent(primaryId));
    await settle();

    expect(bloc.state.activeTab!.id, thirdId);
    expect(bloc.state.splitSecondaryTabId, primaryId);
    expect(bloc.state.focusedTabId, primaryId);
  });

  test('closing the focused pane hands the toolbar back', () async {
    final (bloc, primaryId, secondaryId) = await splitBloc();
    addTearDown(bloc.close);

    bloc.add(FocusSplitPaneEvent(secondaryId));
    await settle();
    bloc.add(RemoveTabEvent(secondaryId));
    await settle();

    expect(bloc.state.tabs.any((t) => t.id == secondaryId), isFalse);
    expect(bloc.state.focusedTabId, primaryId);
    expect(bloc.state.focusedTab!.id, primaryId);
  });
}
