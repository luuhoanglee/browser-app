import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:browser_app/core/logger/analytics_event.dart';
import 'package:browser_app/core/logger/app_logger.dart';
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
    on<AddLoadedResourceEvent>(_onAddLoadedResource);
    on<ClearLoadedResourcesEvent>(_onClearLoadedResources);
    on<ToggleIncognitoModeEvent>(_onToggleIncognitoMode);
    on<EnableSplitViewEvent>(_onEnableSplitView);
    on<DisableSplitViewEvent>(_onDisableSplitView);
    on<SetSplitSecondaryTabEvent>(_onSetSplitSecondaryTab);
    on<UpdateSplitRatioEvent>(_onUpdateSplitRatio);
    on<SetAudioTabEvent>(_onSetAudioTab);

    _init();
  }

  void _init() async {
    // Emit initial state immediately with empty tab to show UI
    final initialTab = TabModel.create(index: 0);
    repository.addTab(initialTab);
    repository.setActiveTab(initialTab.id);

    emit(
      state.copyWith(
        tabs: repository.getTabs(),
        activeTab: repository.getActiveTab(),
        activeTabIndex: 0,
        audioTabId: initialTab.id,
      ),
    );

    // Load cached tabs in background without blocking
    Future.microtask(() async {
      final cachedTabs = await StorageService.loadTabs();
      final activeTabId = await StorageService.loadActiveTabId();

      if (cachedTabs.isEmpty) {
        // No cache found, keep the initial tab we created
        return;
      }

      // Remove the initial placeholder tab
      final initialTab = repository.getTabs().first;
      repository.removeTab(initialTab.id);

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
      if (repository.getTabs().isEmpty ||
          repository.getTabs().every((t) => t.url.isEmpty)) {
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

      emit(
        state.copyWith(
          tabs: repository.getTabs(),
          activeTab: activeTab,
          activeTabIndex: activeIndex == -1 ? 0 : activeIndex,
          audioTabId: activeTab?.id,
        ),
      );
    });
  }

  Future<void> _onAddTab(AddTabEvent event, Emitter<TabState> emit) async {
    final newIndex = state.tabs.length;
    final newTab = TabModel.create(
      index: newIndex,
      isIncognito: state.isIncognitoMode,
    );

    repository.addTab(newTab);
    repository.setActiveTab(newTab.id);

    final updatedTabs = repository.getTabs();
    final activeTab = repository.getActiveTab();

    emit(
      state.copyWith(
        tabs: updatedTabs,
        activeTab: activeTab,
        activeTabIndex: newIndex,
        // A freshly opened, focused tab becomes the audio owner.
        audioTabId: newTab.id,
      ),
    );

    AppLogger.event(
      AnalyticsEvent.tabOpened,
      params: {
        AnalyticsParam.isIncognito: newTab.isIncognito,
        AnalyticsParam.tabCount: updatedTabs.length,
      },
    );

    // Only save non-incognito tabs
    if (!state.isIncognitoMode) {
      await StorageService.saveTabs(updatedTabs, activeTab?.id);
    }
  }

  Future<void> _onToggleIncognitoMode(
    ToggleIncognitoModeEvent event,
    Emitter<TabState> emit,
  ) async {
    final newIncognitoMode = !state.isIncognitoMode;

    // Lưu active tab ID của chế độ hiện tại
    final String? savedNormalTabId;
    final String? savedIncognitoTabId;

    if (state.isIncognitoMode) {
      // Đang chuyển từ incognito sang normal, lưu active tab incognito
      savedIncognitoTabId = state.activeTab?.id;
      savedNormalTabId = state.normalModeActiveTabId;
    } else {
      // Đang chuyển từ normal sang incognito, lưu active tab normal
      savedNormalTabId = state.activeTab?.id;
      savedIncognitoTabId = state.incognitoModeActiveTabId;
    }

    // Tìm tab trong chế độ mới
    final targetTabs = newIncognitoMode
        ? state.tabs.where((t) => t.isIncognito).toList()
        : state.tabs.where((t) => !t.isIncognito).toList();

    if (targetTabs.isEmpty) {
      // Nếu chưa có tab nào trong chế độ mới, tạo tab mới
      final newTab = TabModel.create(
        index: state.tabs.length,
        isIncognito: newIncognitoMode,
      );
      repository.addTab(newTab);
      repository.setActiveTab(newTab.id);

      final updatedTabs = repository.getTabs();
      final activeTab = repository.getActiveTab();
      final activeIndex = repository.getTabIndex(activeTab?.id ?? '');

      emit(
        state.copyWith(
          tabs: updatedTabs,
          activeTab: activeTab,
          activeTabIndex: activeIndex == -1 ? 0 : activeIndex,
          isIncognitoMode: newIncognitoMode,
          normalModeActiveTabId: savedNormalTabId,
          incognitoModeActiveTabId: savedIncognitoTabId,
          isSplitViewEnabled: false,
          splitSecondaryTabId: null,
          audioTabId: activeTab?.id,
        ),
      );
    } else {
      // Nếu đã có tab, khôi phục active tab đã lưu trước đó
      final savedActiveTabId = newIncognitoMode
          ? savedIncognitoTabId
          : savedNormalTabId;

      // Tìm tab đã lưu trong danh sách tabs của chế độ mới
      final tabToActivate = savedActiveTabId != null
          ? targetTabs.firstWhere(
              (t) => t.id == savedActiveTabId,
              orElse: () => targetTabs.first,
            )
          : targetTabs.first;

      repository.setActiveTab(tabToActivate.id);
      final activeTab = repository.getActiveTab();
      final activeIndex = repository.getTabIndex(activeTab?.id ?? '');

      emit(
        state.copyWith(
          activeTab: activeTab,
          activeTabIndex: activeIndex == -1 ? 0 : activeIndex,
          isIncognitoMode: newIncognitoMode,
          normalModeActiveTabId: savedNormalTabId,
          incognitoModeActiveTabId: savedIncognitoTabId,
          isSplitViewEnabled: false,
          splitSecondaryTabId: null,
          audioTabId: activeTab?.id,
        ),
      );
    }

    AppLogger.event(
      AnalyticsEvent.incognitoToggled,
      params: {AnalyticsParam.isIncognito: newIncognitoMode},
    );
  }

  Future<void> _onRemoveTab(
    RemoveTabEvent event,
    Emitter<TabState> emit,
  ) async {
    repository.removeTab(event.tabId);
    var updatedTabs = repository.getTabs();
    var activeTab = repository.getActiveTab();
    var activeIndex = repository.getTabIndex(activeTab?.id ?? '');

    // Lọc tabs theo chế độ hiện tại
    final filteredTabs = state.isIncognitoMode
        ? updatedTabs.where((t) => t.isIncognito).toList()
        : updatedTabs.where((t) => !t.isIncognito).toList();

    // Nếu không còn tab nào trong chế độ hiện tại, tạo tab mới
    if (filteredTabs.isEmpty) {
      final newTab = TabModel.create(
        index: updatedTabs.length,
        isIncognito: state.isIncognitoMode,
      );
      repository.addTab(newTab);
      repository.setActiveTab(newTab.id);
      updatedTabs = repository.getTabs();
      activeTab = repository.getActiveTab();
      activeIndex = repository.getTabIndex(activeTab?.id ?? '');
    }

    final splitStillValid =
        state.isSplitViewEnabled &&
        state.splitSecondaryTabId != null &&
        updatedTabs.any((tab) => tab.id == state.splitSecondaryTabId) &&
        activeTab?.id != state.splitSecondaryTabId;

    // Keep the current audio owner unless its tab was the one closed.
    final audioStillValid = updatedTabs.any(
      (tab) => tab.id == state.audioTabId,
    );

    emit(
      state.copyWith(
        tabs: updatedTabs,
        activeTab: activeTab,
        activeTabIndex: activeIndex == -1 ? 0 : activeIndex,
        isSplitViewEnabled: splitStillValid,
        splitSecondaryTabId: splitStillValid ? state.splitSecondaryTabId : null,
        audioTabId: audioStillValid ? state.audioTabId : activeTab?.id,
      ),
    );

    AppLogger.event(
      AnalyticsEvent.tabClosed,
      params: {
        AnalyticsParam.isIncognito: state.isIncognitoMode,
        AnalyticsParam.tabCount: updatedTabs.length,
      },
    );

    await StorageService.saveTabs(updatedTabs, activeTab?.id);
  }

  Future<void> _onSelectTab(
    SelectTabEvent event,
    Emitter<TabState> emit,
  ) async {
    repository.setActiveTab(event.tabId);

    // Cập nhật lastAccessedAt cho tab được chọn
    final activeTab = repository.getActiveTab();
    if (activeTab != null) {
      final updatedTab = activeTab.copyWith(lastAccessedAt: DateTime.now());
      repository.updateTab(updatedTab);
    }

    final index = repository.getTabIndex(event.tabId);
    final updatedActiveTab = repository.getActiveTab();

    String? nextSplitSecondaryId = state.splitSecondaryTabId;
    var nextSplitEnabled = state.isSplitViewEnabled;
    if (nextSplitEnabled) {
      final candidates = repository
          .getTabs()
          .where(
            (tab) =>
                tab.id != updatedActiveTab?.id &&
                tab.isIncognito == (updatedActiveTab?.isIncognito ?? false),
          )
          .toList();
      final secondaryStillValid = candidates.any(
        (tab) => tab.id == nextSplitSecondaryId,
      );
      if (!secondaryStillValid) {
        nextSplitEnabled = candidates.isNotEmpty;
        nextSplitSecondaryId = candidates.isNotEmpty
            ? candidates.first.id
            : null;
      }
    }

    emit(
      state.copyWith(
        tabs: repository.getTabs(),
        activeTab: updatedActiveTab,
        activeTabIndex: index == -1 ? state.activeTabIndex : index,
        isSplitViewEnabled: nextSplitEnabled,
        splitSecondaryTabId: nextSplitSecondaryId,
        // Switching tabs moves audio to the newly focused tab.
        audioTabId: updatedActiveTab?.id,
      ),
    );

    AppLogger.event(
      AnalyticsEvent.tabSwitched,
      params: {
        AnalyticsParam.isIncognito: updatedActiveTab?.isIncognito ?? false,
        AnalyticsParam.tabCount: repository.getTabs().length,
      },
    );

    await StorageService.saveTabs(repository.getTabs(), updatedActiveTab?.id);
  }

  Future<void> _onUpdateTab(
    UpdateTabEvent event,
    Emitter<TabState> emit,
  ) async {
    // Kiểm tra nếu tab thực sự thay đổi rồi mới emit
    final existingTab = repository.getTabs().firstWhere(
      (t) => t.id == event.tab.id,
      orElse: () => event.tab,
    );

    // Chỉ emit khi URL, title, thumbnail, isLoading thay đổi
    // Hoặc loadProgress thay đổi đáng kể (> 10%)
    final progressDelta = (event.tab.loadProgress - existingTab.loadProgress)
        .abs();
    final hasSignificantProgressChange =
        progressDelta >= 10 ||
        event.tab.loadProgress == 100 ||
        event.tab.loadProgress == 0;

    final hasMeaningfulChange =
        existingTab.url != event.tab.url ||
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
    final updatedActiveTab = state.activeTab?.id == event.tab.id
        ? event.tab
        : state.activeTab;

    emit(state.copyWith(tabs: updatedTabs, activeTab: updatedActiveTab));

    // Skip cache nếu được yêu cầu (cho progress, thumbnail, title changes)
    if (event.skipCache) return;

    // Chỉ lưu cache cho các thay đổi quan trọng (URL, title)
    if (event.tab.url.isNotEmpty || event.tab.title.isNotEmpty) {
      await StorageService.saveTabs(updatedTabs, updatedActiveTab?.id);
    }
  }

  void _onAddLoadedResource(
    AddLoadedResourceEvent event,
    Emitter<TabState> emit,
  ) {
    final tab = repository.getTab(event.tabId);
    if (tab == null) return;

    // Check if resource already exists
    final exists = tab.loadedResources.any((r) => r.url == event.resource.url);
    if (exists) return;

    // Add new resource
    final updatedResources = List<LoadedResource>.from(tab.loadedResources);
    updatedResources.add(event.resource);

    final updatedTab = tab.copyWith(loadedResources: updatedResources);
    repository.updateTab(updatedTab);

    if (state.activeTab?.id == event.tabId) {
      emit(state.copyWith(activeTab: updatedTab));
    }
  }

  void _onClearLoadedResources(
    ClearLoadedResourcesEvent event,
    Emitter<TabState> emit,
  ) {
    final tab = repository.getTab(event.tabId);
    if (tab == null) return;

    final updatedTab = tab.copyWith(loadedResources: []);
    repository.updateTab(updatedTab);

    if (state.activeTab?.id == event.tabId) {
      emit(state.copyWith(activeTab: updatedTab));
    }
  }

  void _onEnableSplitView(EnableSplitViewEvent event, Emitter<TabState> emit) {
    final activeTab = state.activeTab;
    final secondaryTab = repository.getTab(event.secondaryTabId);
    if (activeTab == null ||
        secondaryTab == null ||
        secondaryTab.id == activeTab.id ||
        secondaryTab.isIncognito != activeTab.isIncognito) {
      return;
    }

    emit(
      state.copyWith(
        isSplitViewEnabled: true,
        splitSecondaryTabId: secondaryTab.id,
        splitRatio: state.splitRatio.clamp(0.25, 0.75),
      ),
    );

    AppLogger.event(
      AnalyticsEvent.splitViewToggled,
      params: {
        AnalyticsParam.isIncognito: activeTab.isIncognito,
        AnalyticsParam.success: true,
      },
    );
  }

  void _onDisableSplitView(
    DisableSplitViewEvent event,
    Emitter<TabState> emit,
  ) {
    if (!state.isSplitViewEnabled) return;

    emit(state.copyWith(isSplitViewEnabled: false, splitSecondaryTabId: null));

    AppLogger.event(
      AnalyticsEvent.splitViewToggled,
      params: {
        AnalyticsParam.isIncognito: state.activeTab?.isIncognito ?? false,
        AnalyticsParam.success: false,
      },
    );
  }

  void _onSetSplitSecondaryTab(
    SetSplitSecondaryTabEvent event,
    Emitter<TabState> emit,
  ) {
    final activeTab = state.activeTab;
    final secondaryTab = repository.getTab(event.secondaryTabId);
    if (activeTab == null ||
        secondaryTab == null ||
        secondaryTab.id == activeTab.id ||
        secondaryTab.isIncognito != activeTab.isIncognito) {
      return;
    }

    emit(
      state.copyWith(
        isSplitViewEnabled: true,
        splitSecondaryTabId: secondaryTab.id,
      ),
    );
  }

  void _onUpdateSplitRatio(
    UpdateSplitRatioEvent event,
    Emitter<TabState> emit,
  ) {
    if (!state.isSplitViewEnabled) return;
    final ratio = event.ratio.clamp(0.25, 0.75);
    emit(state.copyWith(splitRatio: ratio));

    AppLogger.event(
      AnalyticsEvent.splitViewResized,
      params: {AnalyticsParam.splitRatio: (ratio * 100).round()},
    );
  }

  void _onSetAudioTab(SetAudioTabEvent event, Emitter<TabState> emit) {
    // The tab must still exist to receive audio.
    final exists = state.tabs.any((tab) => tab.id == event.tabId);
    if (!exists) return;

    // Toggle: tapping the current owner mutes everything; otherwise this pane
    // becomes the sole audio owner. This keeps the "at most one pane has sound"
    // invariant.
    final nextAudioTabId = state.audioTabId == event.tabId ? null : event.tabId;
    if (nextAudioTabId == state.audioTabId) return;

    emit(state.copyWith(audioTabId: nextAudioTabId));

    AppLogger.event(
      AnalyticsEvent.paneAudioToggled,
      params: {AnalyticsParam.hasAudio: nextAudioTabId != null},
    );
  }
}
