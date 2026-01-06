import '../../domain/entities/tab_entity.dart';
import '../../domain/repositories/tab_repository.dart';

class TabRepositoryImpl implements TabRepository {
  final List<TabEntity> _tabs = [];
  String? _activeTabId;

  @override
  List<TabEntity> getTabs() => List.from(_tabs);

  @override
  TabEntity? getTab(String id) {
    try {
      return _tabs.firstWhere((tab) => tab.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void addTab(TabEntity tab) {
    _tabs.add(tab);
  }

  @override
  void removeTab(String id) {
    _tabs.removeWhere((tab) => tab.id == id);
    // Không tự động chuyển sang tab khác khi đóng tab
    if (_activeTabId == id) {
      _activeTabId = null;
    }
  }

  @override
  void updateTab(TabEntity tab) {
    final index = _tabs.indexWhere((t) => t.id == tab.id);
    if (index != -1) {
      _tabs[index] = tab;
    }
  }

  @override
  TabEntity? getActiveTab() {
    if (_activeTabId == null) return null;
    return getTab(_activeTabId!);
  }

  @override
  void setActiveTab(String id) {
    _activeTabId = id;
  }

  @override
  int getTabIndex(String id) {
    return _tabs.indexWhere((tab) => tab.id == id);
  }
}
