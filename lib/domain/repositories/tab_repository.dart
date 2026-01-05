import '../entities/tab_entity.dart';

abstract class TabRepository {
  List<TabEntity> getTabs();

  TabEntity? getTab(String id);

  void addTab(TabEntity tab);

  void removeTab(String id);

  void updateTab(TabEntity tab);

  TabEntity? getActiveTab();

  void setActiveTab(String id);

  int getTabIndex(String id);
}
