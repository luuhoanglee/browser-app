import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:browser_app/core/logger/analytics_event.dart';
import 'package:browser_app/core/logger/app_logger.dart';
import 'package:browser_app/core/logger/analytics_utils.dart';
import 'package:browser_app/core/utils/url_utils.dart';
import '../../../data/repositories/tab_repository_impl.dart';
import '../../../data/services/storage_service.dart';
import '../../../features/tabs/bloc/tab_bloc.dart';
import '../../../features/tabs/bloc/tab_event.dart';
import '../../../features/tabs/bloc/tab_state.dart';
import '../../../features/quick_access/bloc/quick_access_bloc.dart';
import '../../../features/quick_access/bloc/quick_access_event.dart';
import 'widgets/history_sheet.dart';
import 'widgets/bottom_bar_wrapper.dart';
import 'widgets/mini_url_bar_wrapper.dart';
import 'widgets/progress_bar_wrapper.dart';
import 'widgets/page_content_wrapper.dart';
import 'widgets/split_audio_toggle.dart';
import '../../../features/tabs/widgets/empty_page.dart';
import '../../../features/webview/widgets/webview_page.dart';
import '../../../features/tabs/widgets/tabs_sheet.dart';
import '../../../features/search/widgets/search_page.dart';
import '../../../features/search/bloc/search_bloc.dart';
import '../../../features/search/bloc/search_event.dart';
import 'package:browser_app/features/search/search_service.dart';
import '../../../features/media/widgets/media_gallery_sheet.dart';
import '../../../features/download/bloc/download_bloc.dart';
import '../../../features/download/widgets/download_sheet.dart';
import '../../../features/warp/widgets/warp_support_sheet.dart';
import 'bloc/home_ui_cubit.dart';
import 'mixins/status_bar_mixin.dart';
import 'services/nav_history_manager.dart';

class HomePage extends StatelessWidget {
  final String? initialUrl;
  const HomePage({super.key, this.initialUrl});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => TabBloc(TabRepositoryImpl())),
        BlocProvider(create: (context) => SearchBloc()),
        BlocProvider(create: (context) => DownloadBloc()),
        BlocProvider(create: (context) => HomeUiCubit()),
        BlocProvider(
          create: (context) =>
              QuickAccessBloc()..add(const QuickAccessLoadEvent()),
        ),
      ],
      child: HomeViewWrapper(initialUrl: initialUrl),
    );
  }
}

// Wrapper để tạo GlobalKey cho HomeView
class HomeViewWrapper extends StatefulWidget {
  final String? initialUrl;
  const HomeViewWrapper({super.key, this.initialUrl});

  @override
  State<HomeViewWrapper> createState() => HomeViewWrapperState();
}

class HomeViewWrapperState extends State<HomeViewWrapper> {
  final GlobalKey<_HomeViewState> _homeViewKey = GlobalKey<_HomeViewState>();

  @override
  Widget build(BuildContext context) {
    return HomeView(key: _homeViewKey, initialUrl: widget.initialUrl);
  }

  // Method để load deep link từ bên ngoài
  void loadDeepLinkUrl(String url) {
    _homeViewKey.currentState?.loadDeepLinkUrl(url);
  }
}

class HomeView extends StatefulWidget {
  final String? initialUrl;
  const HomeView({super.key, this.initialUrl});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with AutomaticKeepAliveClientMixin, StatusBarMixin {
  final Map<String, InAppWebViewController> _controllers = {};
  final Map<String, GlobalKey> _emptyPageKeys = {};
  final Map<String, GlobalKey> _webViewKeys = {};
  final NavHistoryManager _navManager = NavHistoryManager();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  Timer? _scrollDebounce;
  final List<String> _history = [];
  int _lastProgress = 0;
  Timer? _progressDebounce;

  // One controller per tab: in split view both panes are on screen at once, so
  // a single shared controller would only ever refresh the primary pane.
  final Map<String, PullToRefreshController> _pullToRefreshControllers = {};
  bool _isMediaSheetOpen = false;

  @override
  bool get wantKeepAlive => true;

  InAppWebViewController? _getController(String? tabId) {
    if (tabId == null) return null;
    return _controllers[tabId];
  }

  PullToRefreshController _getPullToRefreshController(String tabId) {
    return _pullToRefreshControllers.putIfAbsent(
      tabId,
      () => PullToRefreshController(
        settings: PullToRefreshSettings(color: Colors.blue),
        onRefresh: () async {
          final controller = _getController(tabId);
          if (controller == null) {
            _pullToRefreshControllers[tabId]?.endRefreshing();
            return;
          }
          await controller.reload();
        },
      ),
    );
  }

  void _setController(String tabId, InAppWebViewController controller) {
    _controllers[tabId] = controller;
  }

  GlobalKey _getEmptyPageKey(String tabId) {
    if (!_emptyPageKeys.containsKey(tabId)) {
      _emptyPageKeys[tabId] = GlobalKey();
    }
    return _emptyPageKeys[tabId]!;
  }

  /// A stable [GlobalKey] per tab. Toggling split view moves a pane's WebView
  /// to a different place in the widget tree; without a GlobalKey Flutter would
  /// tear the element down and the page would reload and lose its scroll
  /// position every time split is turned on or off.
  GlobalKey _getWebViewKey(String tabId) {
    return _webViewKeys.putIfAbsent(tabId, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tab = context.read<TabBloc>().state.activeTab;
      if (tab == null) return;
      final isEmptyTab = tab.url.isEmpty;
      updateStatusBar(
        themeColor: isEmptyTab ? null : tabThemeColor(tab.id),
        isIncognito: tab.isIncognito,
      );
    });
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        loadDeepLinkUrl(widget.initialUrl!);
      });
    }
  }

  void loadDeepLinkUrl(String url) {
    final bloc = context.read<TabBloc>();
    // In split view the deep link opens in whichever pane the user is driving.
    final activeTab = bloc.state.focusedTab;
    if (activeTab != null) {
      AppLogger.info('HomePage', 'Loading deep link URL: $url');
      AppLogger.event(
        AnalyticsEvent.deepLinkOpened,
        params: AnalyticsUtils.navigationParams(url),
      );
      _navManager.addUrl(activeTab.id, url);
      bloc.add(UpdateTabEvent(activeTab.copyWith(url: url)));
      final controller = _getController(activeTab.id);
      if (controller != null) {
        controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollDebounce?.cancel();
    _progressDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await StorageService.loadHistory();
    setState(() {
      _history.clear();
      _history.addAll(history);
    });
  }

  Future<void> _addToHistory(String url) async {
    final bloc = context.read<TabBloc>();
    final tab = bloc.state.activeTab;
    if (tab != null && tab.isIncognito) return;

    _history.remove(url);
    _history.insert(0, url);
    if (_history.length > 100) {
      _history.removeLast();
    }
    StorageService.saveHistory(_history);
  }

  Future<bool> _canNavigateBack(String tabId) async {
    final controller = _getController(tabId);
    if (controller != null && await controller.canGoBack()) return true;
    return _navManager.canGoBackLocal(tabId);
  }

  Future<bool> _canNavigateForward(String tabId) async {
    final controller = _getController(tabId);
    if (controller != null && await controller.canGoForward()) return true;
    return _navManager.canGoForwardLocal(tabId);
  }

  void _handleNavigation(
    BuildContext context,
    String tabId,
    bool isForward,
  ) async {
    final controller = _getController(tabId);
    final bloc = context.read<TabBloc>();
    // Navigate the tab that was asked for — in split view that may be the
    // secondary pane, not the active tab.
    final tabIndex = bloc.state.tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex == -1) return;
    final activeTab = bloc.state.tabs[tabIndex];

    if (isForward) {
      final nextUrl = _navManager.navigateForward(tabId);
      if (nextUrl != null) {
        bloc.add(UpdateTabEvent(activeTab.copyWith(url: nextUrl)));
        controller?.loadUrl(urlRequest: URLRequest(url: WebUri(nextUrl)));
      } else if (controller != null) {
        final canGoForward = await controller.canGoForward();
        if (canGoForward) controller.goForward();
      }
    } else {
      if (controller != null) {
        final canGoBack = await controller.canGoBack();
        if (canGoBack) {
          controller.goBack();
          return;
        }
      }

      final prevUrl = _navManager.navigateBack(tabId);
      if (prevUrl != null) {
        bloc.add(UpdateTabEvent(activeTab.copyWith(url: prevUrl)));
        controller?.loadUrl(urlRequest: URLRequest(url: WebUri(prevUrl)));
      } else if (activeTab.url.isNotEmpty) {
        bloc.add(UpdateTabEvent(activeTab.copyWith(url: '')));
        _navManager.resetIndex(tabId);
      }
    }
  }

  Future<void> _captureThumbnail(String tabId) async {
    try {
      final controller = _getController(tabId);

      if (controller != null) {
        Future.microtask(() async {
          final Uint8List? screenshot = await controller.takeScreenshot();

          if (screenshot != null && mounted) {
            final bloc = context.read<TabBloc>();
            final tab = bloc.state.tabs.firstWhere(
              (t) => t.id == tabId,
              orElse: () => bloc.state.activeTab!,
            );
            bloc.add(
              UpdateTabEvent(
                tab.copyWith(thumbnail: screenshot),
                skipCache: true,
              ),
            );
          }
        });
        return;
      }

      // Nếu không có controller (empty page), chụp từ RepaintBoundary
      final key = _getEmptyPageKey(tabId);

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted || key.currentContext == null) return;

      RenderObject? renderObject = key.currentContext!.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        return;
      }

      final boundary = renderObject;

      Future.microtask(() async {
        try {
          ui.Image image = await boundary.toImage(pixelRatio: 1.0);
          ByteData? byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData == null) return;

          Uint8List pngBytes = byteData.buffer.asUint8List();

          if (mounted) {
            final bloc = context.read<TabBloc>();
            final tab = bloc.state.tabs.firstWhere(
              (t) => t.id == tabId,
              orElse: () => bloc.state.activeTab!,
            );
            bloc.add(
              UpdateTabEvent(
                tab.copyWith(thumbnail: pngBytes),
                skipCache: true,
              ),
            );
          }
        } catch (_) {
          // Silent fail
        }
      });
    } catch (_) {
      // Silent fail for thumbnail capture
    }
  }

  void _performSearch(dynamic activeTab) {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final url = UrlUtils.formatUrl(query);
      _navManager.addUrl(activeTab.id, url);

      final bloc = context.read<TabBloc>();
      bloc.add(UpdateTabEvent(activeTab.copyWith(url: url)));

      final controller = _getController(activeTab.id);
      if (controller != null) {
        controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      }

      setState(() {
        _isSearching = false;
      });
      _searchFocusNode.unfocus();
    }
  }

  void _handleScrollChange(int scrollY) {
    final homeUiCubit = context.read<HomeUiCubit>();
    if ((scrollY - homeUiCubit.state.lastScrollY).abs() < 100) return;

    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      context.read<HomeUiCubit>().handleScrollChange(scrollY);
    });
  }

  void _resetScrollState() {
    context.read<HomeUiCubit>().resetScrollState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<TabBloc, TabState>(
      listenWhen: (prev, curr) =>
          prev.focusedTabId != curr.focusedTabId ||
          prev.isIncognitoMode != curr.isIncognitoMode ||
          (prev.focusedTab?.url.isEmpty ?? true) !=
              (curr.focusedTab?.url.isEmpty ?? true),
      listener: (context, state) {
        // The status bar follows the pane the toolbar is driving.
        final tab = state.focusedTab;
        if (tab == null) return;
        final isEmptyTab = tab.url.isEmpty;
        updateStatusBar(
          themeColor: isEmptyTab ? null : tabThemeColor(tab.id),
          isIncognito: tab.isIncognito,
        );
      },
      child: BlocBuilder<TabBloc, TabState>(
        buildWhen: (previous, current) {
          final prevTab = previous.activeTab;
          final currTab = current.activeTab;

          if (prevTab?.id != currTab?.id) return true;
          if (previous.tabs.length != current.tabs.length) return true;
          if (previous.isSplitViewEnabled != current.isSplitViewEnabled) {
            return true;
          }
          if (previous.splitSecondaryTabId != current.splitSecondaryTabId) {
            return true;
          }
          if (previous.focusedTabId != current.focusedTabId) return true;
          if (previous.splitRatio != current.splitRatio) return true;
          if (previous.audioTabId != current.audioTabId) return true;
          final prevUrlEmpty = prevTab?.url.isEmpty ?? true;
          final currUrlEmpty = currTab?.url.isEmpty ?? true;
          if (prevUrlEmpty != currUrlEmpty) return true;
          return false;
        },
        builder: (context, tabState) {
          final activeTab = tabState.activeTab;
          if (activeTab == null) {
            return const Scaffold(body: SizedBox.shrink());
          }

          // Every toolbar control targets the focused pane. Outside split view
          // that is just the active tab, so behaviour is unchanged.
          final toolbarTab = tabState.focusedTab ?? activeTab;
          final toolbarTabId = toolbarTab.id;

          final isIncognito = activeTab.isIncognito;

          // Colour for the top safe-area strip: the page's own background
          // colour (captured from the page on load) so the status-bar area
          // reads as a seamless extension of the page, Safari-style. Falls back
          // to the scaffold colour until a page reports its colour.
          final topSafeAreaColor = isIncognito
              ? const Color(0xFF1A1A2E)
              : (tabThemeColor(activeTab.id) ?? Colors.white);

          return Scaffold(
            backgroundColor: isIncognito
                ? const Color(0xFF1A1A2E)
                : Colors.white,
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Web content is inset below the top safe area so a
                      // page's top row (header / menu / buttons) is never
                      // hidden behind the status bar. The strip above is painted
                      // with the page's own background colour, so it looks like
                      // a seamless continuation of the page (Safari-style top
                      // safe area) rather than a hard opaque bar.
                      Positioned.fill(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              width: double.infinity,
                              height: MediaQuery.paddingOf(context).top,
                              color: topSafeAreaColor,
                            ),
                            Expanded(
                              child: PageContentWrapper(
                                activeTab: activeTab,
                                tabState: tabState,
                                buildPageContent: _buildPageContent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // When the toolbar is hidden the mini URL pill floats over
                      // the page content instead of the layout reserving a
                      // toolbar strip. A reserved strip would expose the
                      // Scaffold background (white in normal mode) as a band on
                      // dark pages — the bug in issue #21. The pill is the only
                      // hit-testable part, so scrolling/tapping the page still
                      // works around it.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: BlocBuilder<HomeUiCubit, HomeUiState>(
                          buildWhen: (previous, current) =>
                              previous.isToolbarVisible !=
                              current.isToolbarVisible,
                          builder: (context, homeUiState) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0, 0.08),
                                  end: Offset.zero,
                                ).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: slide,
                                    child: child,
                                  ),
                                );
                              },
                              child: homeUiState.isToolbarVisible
                                  ? const SizedBox.shrink(
                                      key: ValueKey('mini_hidden'),
                                    )
                                  : MiniUrlBarWrapper(
                                      key: const ValueKey('toolbar_hidden'),
                                      activeTabId: toolbarTabId,
                                      controller: _getController(toolbarTabId),
                                      onTap: () => _showSearchPage(context),
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<HomeUiCubit, HomeUiState>(
                  buildWhen: (previous, current) =>
                      previous.isToolbarVisible != current.isToolbarVisible,
                  builder: (context, homeUiState) {
                    final isToolbarVisible = homeUiState.isToolbarVisible;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: isToolbarVisible
                          ? Column(
                              key: const ValueKey('toolbar_visible'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ProgressBarWrapper(activeTabId: toolbarTabId),
                                RepaintBoundary(
                                  child: BottomBarWrapper(
                                    activeTabId: toolbarTabId,
                                    controller: _getController(toolbarTabId),
                                    onShowTabs: () => _showTabsSheet(context),
                                    onAddressBarTap: () =>
                                        _showSearchPage(context),
                                    onShowHistory: () =>
                                        _showHistorySheet(context),
                                    onShowDownload: () =>
                                        _showDownloadSheet(context),
                                    onShowMedia: () => _showMediaSheet(context),
                                    onShowWarp: () =>
                                        WarpSupportSheet.show(context),
                                    isSearching: _isSearching,
                                    isMediaSheetOpen: _isMediaSheetOpen,
                                    searchController: _searchController,
                                    searchFocusNode: _searchFocusNode,
                                    onSearch: (query) {
                                      _searchController.text = query;
                                      context.read<SearchBloc>().add(
                                        PerformSearchEvent(query),
                                      );
                                      final bloc = context.read<TabBloc>();
                                      final currentTab = bloc.state.focusedTab;
                                      if (currentTab != null) {
                                        _performSearch(currentTab);
                                      }
                                    },
                                    onBack: () => _handleNavigation(
                                      context,
                                      toolbarTabId,
                                      false,
                                    ),
                                    onForward: () => _handleNavigation(
                                      context,
                                      toolbarTabId,
                                      true,
                                    ),
                                    canGoBack: () =>
                                        _canNavigateBack(toolbarTabId),
                                    canGoForward: () =>
                                        _canNavigateForward(toolbarTabId),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('toolbar_hidden_placeholder'),
                            ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageContent(
    BuildContext context,
    dynamic activeTab,
    TabState tabState,
  ) {
    final secondaryTab = tabState.splitSecondaryTab;
    final canShowSplit =
        tabState.isSplitViewEnabled &&
        secondaryTab != null &&
        secondaryTab.id != activeTab.id &&
        secondaryTab.isIncognito == activeTab.isIncognito;

    if (canShowSplit) {
      return _buildSplitPageContent(context, activeTab, secondaryTab, tabState);
    }

    return Stack(
      children: tabState.tabs.map((tab) {
        return Offstage(
          offstage: tab.id != activeTab.id,
          child: _buildTabPane(
            context,
            tab,
            tab.id == activeTab.id,
            muted: tabState.isTabMuted(tab.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSplitPageContent(
    BuildContext context,
    dynamic activeTab,
    dynamic secondaryTab,
    TabState tabState,
  ) {
    final hiddenTabs = tabState.tabs
        .where((tab) => tab.id != activeTab.id && tab.id != secondaryTab.id)
        .map(
          (tab) => Offstage(
            offstage: true,
            child: _buildTabPane(
              context,
              tab,
              false,
              muted: tabState.isTabMuted(tab.id),
            ),
          ),
        )
        .toList();

    final primaryMuted = tabState.isTabMuted(activeTab.id);
    final secondaryMuted = tabState.isTabMuted(secondaryTab.id);
    final primaryFocused = tabState.isPaneFocused(activeTab.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final ratio = tabState.splitRatio.clamp(0.25, 0.75);

        final primaryPane = Expanded(
          flex: (ratio * 1000).round(),
          child: _buildSplitPane(
            context,
            activeTab,
            muted: primaryMuted,
            isFocused: primaryFocused,
          ),
        );
        final secondaryPane = Expanded(
          flex: ((1 - ratio) * 1000).round(),
          child: _buildSplitPane(
            context,
            secondaryTab,
            muted: secondaryMuted,
            isFocused: !primaryFocused,
          ),
        );
        final divider = _buildSplitDivider(context, isLandscape, constraints);

        final splitLayout = isLandscape
            ? Row(children: [primaryPane, divider, secondaryPane])
            : Column(children: [primaryPane, divider, secondaryPane]);

        return Stack(children: [...hiddenTabs, splitLayout]);
      },
    );
  }

  /// One split pane. The focused pane is the one the bottom bar drives, so it
  /// is marked with an accent ring; touching the other pane moves focus (and
  /// therefore the whole toolbar) to it.
  Widget _buildSplitPane(
    BuildContext context,
    dynamic tab, {
    required bool muted,
    required bool isFocused,
  }) {
    // A Listener only observes the pointer — it never claims the gesture, so
    // taps, scrolls and text selection still reach the WebView underneath.
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) {
        final bloc = context.read<TabBloc>();
        if (bloc.state.focusedTabId != tab.id) {
          bloc.add(FocusSplitPaneEvent(tab.id));
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused
                ? Colors.blue
                : Colors.black.withValues(alpha: 0.12),
            width: isFocused ? 2 : 1,
          ),
        ),
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: _buildTabPane(context, tab, isFocused, muted: muted),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: SplitAudioToggle(
                  muted: muted,
                  onToggle: () =>
                      context.read<TabBloc>().add(SetAudioTabEvent(tab.id)),
                ),
              ),
              // Tells the user which page the bottom bar is currently driving.
              if (isFocused)
                Positioned(
                  top: 8,
                  left: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitDivider(
    BuildContext context,
    bool isLandscape,
    BoxConstraints constraints,
  ) {
    const dividerExtent = 14.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        final bloc = context.read<TabBloc>();
        final delta = isLandscape
            ? details.delta.dx / constraints.maxWidth
            : details.delta.dy / constraints.maxHeight;
        bloc.add(UpdateSplitRatioEvent(bloc.state.splitRatio + delta));
      },
      child: MouseRegion(
        cursor: isLandscape
            ? SystemMouseCursors.resizeLeftRight
            : SystemMouseCursors.resizeUpDown,
        child: Container(
          width: isLandscape ? dividerExtent : double.infinity,
          height: isLandscape ? double.infinity : dividerExtent,
          color: Colors.black.withOpacity(0.06),
          alignment: Alignment.center,
          child: Container(
            width: isLandscape ? 3 : 44,
            height: isLandscape ? 44 : 3,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.32),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  /// [isFocused] marks the pane the toolbar is driving. In split view both
  /// panes are live; only the focused one may drive shared chrome (status bar
  /// colour, toolbar auto-hide).
  Widget _buildTabPane(
    BuildContext context,
    dynamic tab,
    bool isFocused, {
    bool muted = false,
  }) {
    if (tab.url.isEmpty) {
      return RepaintBoundary(
        key: ValueKey('empty_boundary_${tab.id}'),
        child: EmptyPage(
          key: ValueKey('empty_${tab.id}'),
          activeTab: tab,
          onSearchBarTap: () => _showSearchPage(context),
          onQuickAccessTap: (url) {
            _resetScrollState();
            final formatted = UrlUtils.formatUrl(url);
            _navManager.addUrl(tab.id, formatted);
            final bloc = context.read<TabBloc>();
            bloc.add(UpdateTabEvent(tab.copyWith(url: formatted)));
            final controller = _getController(tab.id);
            if (controller != null) {
              controller.loadUrl(
                urlRequest: URLRequest(url: WebUri(formatted)),
              );
            }
          },
        ),
      );
    }

    return WebViewPage(
      key: _getWebViewKey(tab.id),
      activeTab: tab,
      controller: _getController(tab.id),
      muted: muted,
      // Each pane gets its own controller so pull-to-refresh reloads the page
      // it was performed on, not whichever tab happens to be active.
      pullToRefreshController: _getPullToRefreshController(tab.id),
      onWebViewCreated: (controller) => _setController(tab.id, controller),
      onUpdateVisitedHistory: (controller, url, isReload) {
        final bloc = context.read<TabBloc>();
        final currentTab = bloc.state.tabs.firstWhere(
          (t) => t.id == tab.id,
          orElse: () => tab,
        );
        final urlStr = url?.toString() ?? '';
        if (urlStr.isNotEmpty &&
            !urlStr.startsWith('intent://') &&
            !UrlUtils.isExternalUrl(urlStr) &&
            currentTab.url != urlStr) {
          bloc.add(
            UpdateTabEvent(currentTab.copyWith(url: urlStr), skipCache: true),
          );
        }
      },
      onUrlUpdated: (newUrl) {
        final bloc = context.read<TabBloc>();
        final currentTab = bloc.state.tabs.firstWhere(
          (t) => t.id == tab.id,
          orElse: () => tab,
        );
        if (newUrl.isNotEmpty) {
          bloc.add(
            UpdateTabEvent(currentTab.copyWith(url: newUrl), skipCache: false),
          );
        }
      },
      onLoadStart: (controller, url) {
        if (isFocused) _resetScrollState();
        final bloc = context.read<TabBloc>();
        final currentTab = bloc.state.tabs.firstWhere(
          (t) => t.id == tab.id,
          orElse: () => tab,
        );
        final urlStr = url?.toString() ?? '';
        if (!urlStr.startsWith('intent://') &&
            !UrlUtils.isExternalUrl(urlStr) &&
            currentTab.url != urlStr) {
          bloc.add(
            UpdateTabEvent(currentTab.copyWith(url: urlStr), skipCache: true),
          );
        }
      },
      onLoadStop: (controller, url) async {
        _pullToRefreshControllers[tab.id]?.endRefreshing();
        final bloc = context.read<TabBloc>();
        final currentTab = bloc.state.tabs.firstWhere(
          (t) => t.id == tab.id,
          orElse: () => tab,
        );
        final urlStr = url?.toString() ?? '';
        if (url != null &&
            urlStr.isNotEmpty &&
            !urlStr.startsWith('intent://') &&
            !UrlUtils.isExternalUrl(urlStr)) {
          if (tab.url.isNotEmpty && isFocused) {
            await syncSystemUiFromWebPage(
              controller: controller,
              tabId: tab.id,
              isIncognito: currentTab.isIncognito,
            );
            // Rebuild so the top safe-area strip picks up the freshly captured
            // page background colour.
            if (mounted) setState(() {});
          }
          final title = await controller.getTitle();
          if (title != null &&
              title.isNotEmpty &&
              currentTab.title == 'New Tab') {
            bloc.add(
              UpdateTabEvent(
                currentTab.copyWith(title: title),
                skipCache: true,
              ),
            );
          } else if (currentTab.title == 'New Tab' ||
              currentTab.title.isEmpty) {
            final uri = Uri.tryParse(urlStr);
            final fallbackTitle = uri?.host ?? UrlUtils.formatUrlTitle(urlStr);
            if (fallbackTitle.isNotEmpty) {
              bloc.add(
                UpdateTabEvent(
                  currentTab.copyWith(title: fallbackTitle),
                  skipCache: true,
                ),
              );
            }
          }

          Future.delayed(const Duration(milliseconds: 500), () {
            AppLogger.event(
              AnalyticsEvent.pageLoaded,
              params: AnalyticsUtils.navigationParams(urlStr),
            );
            _captureThumbnail(tab.id);
            _addToHistory(urlStr);
          });
        }
      },
      onTitleChanged: (controller, title) {
        final bloc = context.read<TabBloc>();
        final currentTab = bloc.state.tabs.firstWhere(
          (t) => t.id == tab.id,
          orElse: () => tab,
        );
        if (title != null && title.isNotEmpty && currentTab.title != title) {
          bloc.add(
            UpdateTabEvent(currentTab.copyWith(title: title), skipCache: true),
          );
        }
      },
      onProgressChanged: (controller, progress) {
        final shouldUpdate =
            (progress - _lastProgress).abs() >= 20 ||
            progress == 100 ||
            (progress == 0 && _lastProgress != 0);

        if (!shouldUpdate) return;

        _lastProgress = progress;
        _progressDebounce?.cancel();
        _progressDebounce = Timer(const Duration(milliseconds: 100), () {
          if (!mounted) return;

          final bloc = context.read<TabBloc>();
          final currentTab = bloc.state.tabs.firstWhere(
            (t) => t.id == tab.id,
            orElse: () => tab,
          );
          bloc.add(
            UpdateTabEvent(
              currentTab.copyWith(
                loadProgress: progress,
                isLoading: progress < 100,
              ),
              skipCache: true,
            ),
          );
        });
      },
      // Only the focused pane may collapse/expand the toolbar — otherwise the
      // other pane's scrolling fights it.
      onScrollChanged: (y) {
        if (!isFocused) return;
        _handleScrollChange(y);
      },
      onSwipeBack: () => _handleNavigation(context, tab.id, false),
      onSwipeForward: () => _handleNavigation(context, tab.id, true),
    );
  }

  // ── Sheet helpers ────────────────────────────────────────────────────────────

  void _showTabsSheet(BuildContext context) {
    if (_isSearching) {
      setState(() => _isSearching = false);
    }
    _searchFocusNode.unfocus();

    final bloc = context.read<TabBloc>();
    final activeTabId = bloc.state.activeTab?.id;
    if (activeTabId != null) {
      _captureThumbnail(activeTabId);
    }
    // Both split panes are on screen, so refresh both thumbnails.
    final secondaryTabId = bloc.state.isSplitViewEnabled
        ? bloc.state.splitSecondaryTabId
        : null;
    if (secondaryTabId != null) {
      _captureThumbnail(secondaryTabId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<TabBloc>(),
        child: TabsSheet(
          onCloseTab: (tabId) {
            context.read<TabBloc>().add(RemoveTabEvent(tabId));
            _controllers.remove(tabId);
            _webViewKeys.remove(tabId);
            _pullToRefreshControllers.remove(tabId);
            if (_isSearching) {
              _searchController.clear();
              setState(() => _isSearching = false);
            }
          },
          onSelectTab: (tabId) {
            final bloc = context.read<TabBloc>();
            final currentTabId = bloc.state.activeTab?.id;

            if (currentTabId != null && currentTabId != tabId) {
              _captureThumbnail(currentTabId);
            }

            bloc.add(SelectTabEvent(tabId));

            final selectedTab = bloc.state.tabs.firstWhere(
              (t) => t.id == tabId,
            );
            if (selectedTab.thumbnail == null) {
              Future.delayed(const Duration(milliseconds: 100), () {
                _captureThumbnail(tabId);
              });
            }

            Navigator.pop(sheetContext);
          },
          onAddTab: () => Navigator.pop(sheetContext),
        ),
      ),
    ).then((_) => _refreshWebViewForInteraction());
  }

  void _refreshWebViewForInteraction() {}

  void _showHistorySheet(BuildContext context) {
    if (_isSearching) {
      setState(() => _isSearching = false);
    }
    _searchFocusNode.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => HistorySheet(
        history: _history,
        onSelectHistory: (url) {
          final bloc = context.read<TabBloc>();
          final currentTab = bloc.state.focusedTab;
          if (currentTab != null) {
            _navManager.addUrl(currentTab.id, url);
            bloc.add(UpdateTabEvent(currentTab.copyWith(url: url)));
            final controller = _getController(currentTab.id);
            if (controller != null) {
              controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
            }
          }
        },
        onClearHistory: () {
          setState(() => _history.clear());
          StorageService.saveHistory(_history);
        },
        onRemoveHistory: (url) {
          setState(() => _history.remove(url));
          StorageService.saveHistory(_history);
        },
      ),
    ).then((_) => _refreshWebViewForInteraction());
  }

  void _showDownloadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _buildDownloadSheet(sheetContext, context, 0.6),
    ).then((_) => _refreshWebViewForInteraction());
  }

  void _showDownloadSheetExpanded(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _buildDownloadSheet(sheetContext, context, 0.9),
    ).then((_) => _refreshWebViewForInteraction());
  }

  Widget _buildDownloadSheet(
    BuildContext sheetContext,
    BuildContext parentContext,
    double heightFactor,
  ) {
    final isExpanded = heightFactor > 0.7;
    return BlocProvider.value(
      value: parentContext.read<DownloadBloc>(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity!.abs() > 300) {
            Navigator.pop(sheetContext);
            if (details.primaryVelocity! < 0 && !isExpanded) {
              _showDownloadSheetExpanded(parentContext);
            } else if (details.primaryVelocity! > 0 && isExpanded) {
              showModalBottomSheet(
                context: parentContext,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) =>
                    _buildDownloadSheet(sheetContext, parentContext, 0.6),
              );
            }
          }
        },
        child: Container(
          height: MediaQuery.of(parentContext).size.height * heightFactor,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: DownloadSheet(
            heightFactor: 1.0,
            onClose: () => Navigator.pop(sheetContext),
            onExpand: null,
          ),
        ),
      ),
    );
  }

  void _showMediaSheet(BuildContext context) {
    final bloc = context.read<TabBloc>();
    // Show the media of the pane the user is driving, not always the primary.
    final activeTab = bloc.state.focusedTab;
    final controller = _getController(activeTab?.id);

    if (controller == null) return;

    final loadedResources = activeTab?.loadedResources ?? [];
    AppLogger.event(
      AnalyticsEvent.mediaGalleryOpened,
      params: {AnalyticsParam.resourceCount: loadedResources.length},
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _buildMediaSheet(
        sheetContext,
        context,
        controller,
        loadedResources,
        0.62,
      ),
    ).then((_) => _refreshWebViewForInteraction());
  }

  Widget _buildMediaSheet(
    BuildContext sheetContext,
    BuildContext parentContext,
    InAppWebViewController controller,
    List<LoadedResource> loadedResources,
    double heightFactor,
  ) {
    return BlocProvider.value(
      value: parentContext.read<DownloadBloc>(),
      child: DraggableScrollableSheet(
        initialChildSize: heightFactor,
        minChildSize: 0.42,
        maxChildSize: 0.96,
        snap: true,
        snapSizes: const [0.62, 0.96],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 30,
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: MediaGallerySheet(
                    controller: controller,
                    loadedResources: loadedResources,
                    scrollController: scrollController,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSearchPage(BuildContext context) {
    final bloc = context.read<TabBloc>();
    final searchBloc = context.read<SearchBloc>();
    // Typing a URL loads it into the focused pane.
    final currentTab = bloc.state.focusedTab;
    if (currentTab == null) return;

    if (_isSearching) {
      setState(() => _isSearching = false);
    }
    _searchFocusNode.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      routeSettings: const RouteSettings(name: '/search_page'),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minWidth: double.infinity,
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: searchBloc,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 300) {
              Navigator.pop(sheetContext);
            }
          },
          child: SearchPage(
            initialUrl: currentTab.url.isNotEmpty ? currentTab.url : null,
            skipHistory: currentTab.isIncognito,
            onSearch: (query) {
              final url = SearchService.formatInput(query);
              _navManager.addUrl(currentTab.id, url);
              bloc.add(UpdateTabEvent(currentTab.copyWith(url: url)));
              final controller = _getController(currentTab.id);
              if (controller != null) {
                controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
              }
            },
          ),
        ),
      ),
    ).then((_) => _refreshWebViewForInteraction());
  }
}
