import '../../../domain/entities/tab_entity.dart';

class TabState {
  final List<TabEntity> tabs;
  final TabEntity? activeTab;
  final int activeTabIndex;
  final bool isIncognitoMode;
  final String? normalModeActiveTabId;
  final String? incognitoModeActiveTabId;

  const TabState({
    this.tabs = const [],
    this.activeTab,
    this.activeTabIndex = 0,
    this.isIncognitoMode = false,
    this.normalModeActiveTabId,
    this.incognitoModeActiveTabId,
  });

  TabState copyWith({
    List<TabEntity>? tabs,
    TabEntity? activeTab,
    int? activeTabIndex,
    bool? isIncognitoMode,
    String? normalModeActiveTabId,
    String? incognitoModeActiveTabId,
  }) {
    return TabState(
      tabs: tabs ?? this.tabs,
      activeTab: activeTab ?? this.activeTab,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isIncognitoMode: isIncognitoMode ?? this.isIncognitoMode,
      normalModeActiveTabId: normalModeActiveTabId ?? this.normalModeActiveTabId,
      incognitoModeActiveTabId: incognitoModeActiveTabId ?? this.incognitoModeActiveTabId,
    );
  }

  // Get filtered tabs based on incognito mode
  List<TabEntity> get filteredTabs {
    if (isIncognitoMode) {
      return tabs.where((tab) => tab.isIncognito).toList();
    }
    return tabs.where((tab) => !tab.isIncognito).toList();
  }
}
