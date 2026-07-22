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
    );
  }

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
}
