import '../../../domain/entities/tab_entity.dart';

const Object _unset = Object();

class TabState {
  final List<TabEntity> tabs;
  final TabEntity? activeTab;
  final int activeTabIndex;
  final bool isIncognitoMode;
  final String? normalModeActiveTabId;
  final String? incognitoModeActiveTabId;
  final bool isSplitViewEnabled;
  final String? splitSecondaryTabId;
  final double splitRatio;

  /// Id of the split pane the toolbar currently drives (URL bar, back/forward,
  /// reload, progress, search, media). Without this the bar could only ever
  /// reach [activeTab], leaving the secondary pane impossible to operate.
  /// `null` falls back to [activeTab]; it is always ignored outside split view.
  final String? focusedPaneTabId;

  /// Id of the single tab currently allowed to play audio. All other tabs /
  /// split panes are muted so that, on Android, only one media session holds
  /// audio focus — letting multiple videos play their picture at once (issue
  /// #20). `null` means every pane is muted.
  final String? audioTabId;

  const TabState({
    this.tabs = const [],
    this.activeTab,
    this.activeTabIndex = 0,
    this.isIncognitoMode = false,
    this.normalModeActiveTabId,
    this.incognitoModeActiveTabId,
    this.isSplitViewEnabled = false,
    this.splitSecondaryTabId,
    this.splitRatio = 0.5,
    this.focusedPaneTabId,
    this.audioTabId,
  });

  TabState copyWith({
    List<TabEntity>? tabs,
    TabEntity? activeTab,
    int? activeTabIndex,
    bool? isIncognitoMode,
    String? normalModeActiveTabId,
    String? incognitoModeActiveTabId,
    bool? isSplitViewEnabled,
    Object? splitSecondaryTabId = _unset,
    double? splitRatio,
    Object? focusedPaneTabId = _unset,
    Object? audioTabId = _unset,
  }) {
    return TabState(
      tabs: tabs ?? this.tabs,
      activeTab: activeTab ?? this.activeTab,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isIncognitoMode: isIncognitoMode ?? this.isIncognitoMode,
      normalModeActiveTabId:
          normalModeActiveTabId ?? this.normalModeActiveTabId,
      incognitoModeActiveTabId:
          incognitoModeActiveTabId ?? this.incognitoModeActiveTabId,
      isSplitViewEnabled: isSplitViewEnabled ?? this.isSplitViewEnabled,
      splitSecondaryTabId: identical(splitSecondaryTabId, _unset)
          ? this.splitSecondaryTabId
          : splitSecondaryTabId as String?,
      splitRatio: splitRatio ?? this.splitRatio,
      focusedPaneTabId: identical(focusedPaneTabId, _unset)
          ? this.focusedPaneTabId
          : focusedPaneTabId as String?,
      audioTabId: identical(audioTabId, _unset)
          ? this.audioTabId
          : audioTabId as String?,
    );
  }

  /// Whether [tabId]'s WebView should be muted. Only [audioTabId] keeps sound;
  /// at most one pane is ever unmuted.
  bool isTabMuted(String tabId) => tabId != audioTabId;

  // Get filtered tabs based on incognito mode
  List<TabEntity> get filteredTabs {
    if (isIncognitoMode) {
      return tabs.where((tab) => tab.isIncognito).toList();
    }
    return tabs.where((tab) => !tab.isIncognito).toList();
  }

  TabEntity? get splitSecondaryTab {
    final id = splitSecondaryTabId;
    if (id == null) return null;
    for (final tab in tabs) {
      if (tab.id == id) return tab;
    }
    return null;
  }

  /// The tab every toolbar control acts on. In split view this is whichever
  /// pane the user last touched; everywhere else it is simply [activeTab].
  String? get focusedTabId {
    if (!isSplitViewEnabled) return activeTab?.id;
    final id = focusedPaneTabId;
    if (id == null) return activeTab?.id;
    // Only the two visible panes may hold focus.
    if (id != activeTab?.id && id != splitSecondaryTabId) return activeTab?.id;
    return id;
  }

  TabEntity? get focusedTab {
    final id = focusedTabId;
    if (id == null) return activeTab;
    for (final tab in tabs) {
      if (tab.id == id) return tab;
    }
    return activeTab;
  }

  /// True when [tabId] is the pane the toolbar is driving.
  bool isPaneFocused(String tabId) => tabId == focusedTabId;
}
