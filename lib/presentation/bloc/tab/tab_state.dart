import '../../../domain/entities/tab_entity.dart';

class TabState {
  final List<TabEntity> tabs;
  final TabEntity? activeTab;
  final int activeTabIndex;

  const TabState({
    this.tabs = const [],
    this.activeTab,
    this.activeTabIndex = 0,
  });

  TabState copyWith({
    List<TabEntity>? tabs,
    TabEntity? activeTab,
    int? activeTabIndex,
  }) {
    return TabState(
      tabs: tabs ?? this.tabs,
      activeTab: activeTab ?? this.activeTab,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}
