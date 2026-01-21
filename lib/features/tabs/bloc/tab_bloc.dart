import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/tab_model.dart';
import '../../../../data/repositories/tab_repository_impl.dart';
import '../../../../data/services/storage_service.dart';
import 'tab_event.dart';
import 'tab_state.dart';

class TabBloc extends Bloc<TabEvent, TabState> {
  final TabRepositoryImpl repository;

  TabBloc(this.repository) : super(const TabState()) {
    on<AddTabEvent>(_onAddTab);
    on<RemoveTabEvent>(_onRemoveTab);
    on<SelectTabEvent>(_onSelectTab);
    on<UpdateTabEvent>(_onUpdateTab);

    _init();
  }

  void _init() async {
    // Try to load from cache first
    final cachedTabs = await StorageService.loadTabs();
    final activeTabId = await StorageService.loadActiveTabId();

    if (cachedTabs.isNotEmpty) {
      bool hasInvalidTabs = false;

      // Load cached tabs into repository, filter out intent URLs
      for (var tab in cachedTabs) {
        // Skip tabs với intent:// hoặc external URLs
        if (tab.url.startsWith('intent://') ||
            tab.url.startsWith('googlechrome://') ||
            tab.url.startsWith('firefox://') ||
            tab.url.startsWith('chrome://') ||
            tab.url.startsWith('edge://') ||
            tab.url.startsWith('opera://')) {
          print('🚫 Skipping invalid tab with URL: ${tab.url}');
          hasInvalidTabs = true;
          continue;
        }
        repository.addTab(tab);
      }

      // Nếu tất cả tabs đều invalid hoặc chỉ còn empty tabs, tạo tab mới
      if (repository.getTabs().isEmpty || repository.getTabs().every((t) => t.url.isEmpty)) {
        print('🧹 Clearing invalid tabs, creating new tab');
        // Xóa tabs trong repository bằng cách remove từng tab
        for (var tab in repository.getTabs()) {
          repository.removeTab(tab.id);
        }
        final initialTab = TabModel.create(index: 0);
        repository.addTab(initialTab);
        repository.setActiveTab(initialTab.id);
        // Save cleaned state
        StorageService.saveTabs(repository.getTabs(), initialTab.id);
      } else if (activeTabId != null) {
        // Kiểm tra nếu activeTabId vẫn còn valid
        final activeTabStillExists = repository.getTab(activeTabId) != null;
        if (activeTabStillExists) {
          repository.setActiveTab(activeTabId);
        } else {
          // Active tab bị xóa, set tab đầu tiên
          repository.setActiveTab(repository.getTabs().first.id);
        }
      } else {
        repository.setActiveTab(repository.getTabs().first.id);
      }

      final activeTab = repository.getActiveTab();
      final activeIndex = repository.getTabIndex(activeTab?.id ?? '');

      emit(state.copyWith(
        tabs: repository.getTabs(),
        activeTab: activeTab,
        activeTabIndex: activeIndex == -1 ? 0 : activeIndex,
      ));
    } else {
      // Create initial tab if no cache
      final initialTab = TabModel.create(index: 0);
      repository.addTab(initialTab);
      repository.setActiveTab(initialTab.id);

      emit(state.copyWith(
        tabs: repository.getTabs(),
        activeTab: repository.getActiveTab(),
        activeTabIndex: 0,
      ));
    }
  }

  Future<void> _onAddTab(AddTabEvent event, Emitter<TabState> emit) async {
    final newIndex = state.tabs.length;
    final newTab = TabModel.create(index: newIndex);

    repository.addTab(newTab);
    repository.setActiveTab(newTab.id);

    final updatedTabs = repository.getTabs();
    final activeTab = repository.getActiveTab();

    emit(state.copyWith(
      tabs: updatedTabs,
      activeTab: activeTab,
      activeTabIndex: newIndex,
    ));

    await StorageService.saveTabs(updatedTabs, activeTab?.id);
  }

  Future<void> _onRemoveTab(RemoveTabEvent event, Emitter<TabState> emit) async {
    repository.removeTab(event.tabId);
    var updatedTabs = repository.getTabs();
    var activeTab = repository.getActiveTab();
    var activeIndex = repository.getTabIndex(activeTab?.id ?? '');

    // Chỉ tạo empty page nếu không còn tab nào
    if (updatedTabs.isEmpty) {
      final newTab = TabModel.create(index: 0);
      repository.addTab(newTab);
      repository.setActiveTab(newTab.id);
      updatedTabs = repository.getTabs();
      activeTab = repository.getActiveTab();
      activeIndex = 0;
    }

    emit(state.copyWith(
      tabs: updatedTabs,
      activeTab: activeTab,
      activeTabIndex: activeIndex == -1 ? 0 : activeIndex,
    ));

    await StorageService.saveTabs(updatedTabs, activeTab?.id);
  }

  Future<void> _onSelectTab(SelectTabEvent event, Emitter<TabState> emit) async {
    repository.setActiveTab(event.tabId);

    // Cập nhật lastAccessedAt cho tab được chọn
    final activeTab = repository.getActiveTab();
    if (activeTab != null) {
      final updatedTab = activeTab.copyWith(lastAccessedAt: DateTime.now());
      repository.updateTab(updatedTab);
    }

    final index = repository.getTabIndex(event.tabId);
    final updatedActiveTab = repository.getActiveTab();

    emit(state.copyWith(
      tabs: repository.getTabs(),
      activeTab: updatedActiveTab,
      activeTabIndex: index == -1 ? state.activeTabIndex : index,
    ));

    await StorageService.saveTabs(repository.getTabs(), updatedActiveTab?.id);
  }

  Future<void> _onUpdateTab(UpdateTabEvent event, Emitter<TabState> emit) async {
    // Kiểm tra nếu tab thực sự thay đổi rồi mới emit
    final existingTab = repository.getTabs().firstWhere(
      (t) => t.id == event.tab.id,
      orElse: () => event.tab,
    );

    // Chỉ emit khi URL, title, thumbnail, isLoading thay đổi
    // Hoặc loadProgress thay đổi đáng kể (> 10%)
    final progressDelta = (event.tab.loadProgress - existingTab.loadProgress).abs();
    final hasSignificantProgressChange = progressDelta >= 10 || event.tab.loadProgress == 100 || event.tab.loadProgress == 0;

    final hasMeaningfulChange = existingTab.url != event.tab.url ||
        existingTab.title != event.tab.title ||
        existingTab.thumbnail != event.tab.thumbnail ||
        existingTab.isLoading != event.tab.isLoading ||
        hasSignificantProgressChange;

    // Nếu chỉ có loadProgress thay đổi nhỏ, không emit state
    // Chỉ update trong repository để các widget con có thể truy cập
    if (!hasMeaningfulChange && !event.forceUpdate) {
      repository.updateTab(event.tab);
      return;
    }

    repository.updateTab(event.tab);

    final updatedTabs = repository.getTabs();
    final updatedActiveTab = state.activeTab?.id == event.tab.id ? event.tab : state.activeTab;

    emit(state.copyWith(
      tabs: updatedTabs,
      activeTab: updatedActiveTab,
    ));

    // Skip cache nếu được yêu cầu (cho progress, thumbnail, title changes)
    if (event.skipCache) return;

    // Chỉ lưu cache cho các thay đổi quan trọng (URL, title)
    if (event.tab.url.isNotEmpty || event.tab.title.isNotEmpty) {
      await StorageService.saveTabs(updatedTabs, updatedActiveTab?.id);
    }
  }
}
