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
      // Load cached tabs into repository
      for (var tab in cachedTabs) {
        repository.addTab(tab);
      }

      if (activeTabId != null) {
        repository.setActiveTab(activeTabId);
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
    final index = repository.getTabIndex(event.tabId);
    final activeTab = repository.getActiveTab();

    emit(state.copyWith(
      tabs: repository.getTabs(),
      activeTab: activeTab,
      activeTabIndex: index == -1 ? state.activeTabIndex : index,
    ));

    await StorageService.saveTabs(repository.getTabs(), activeTab?.id);
  }

  Future<void> _onUpdateTab(UpdateTabEvent event, Emitter<TabState> emit) async {
    // Kiểm tra nếu tab thực sự thay đổi rồi mới emit
    final existingTab = repository.getTabs().firstWhere(
      (t) => t.id == event.tab.id,
      orElse: () => event.tab,
    );

    // Chỉ emit khi URL, title, thumbnail, isLoading, hoặc loadProgress thay đổi
    final hasMeaningfulChange = existingTab.url != event.tab.url ||
        existingTab.title != event.tab.title ||
        existingTab.thumbnail != event.tab.thumbnail ||
        existingTab.isLoading != event.tab.isLoading ||
        existingTab.loadProgress != event.tab.loadProgress;

    if (!hasMeaningfulChange && !event.forceUpdate) {
      // Chỉ update trong repository, không emit state
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
