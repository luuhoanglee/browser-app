import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../data/repositories/tab_repository_impl.dart';
import '../../../data/services/storage_service.dart';
import '../../../features/tabs/bloc/tab_bloc.dart';
import '../../../features/tabs/bloc/tab_event.dart';
import '../../../features/tabs/bloc/tab_state.dart';
import '../../../features/quick_access/bloc/quick_access_bloc.dart';
import '../../../features/quick_access/bloc/quick_access_event.dart';
import 'widgets/mini_url_bar.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/history_sheet.dart';
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
    with AutomaticKeepAliveClientMixin {
  final Map<String, InAppWebViewController> _controllers = {};
  final Map<String, GlobalKey> _emptyPageKeys = {};
  final Map<String, Color> _tabThemeColors = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _isToolbarVisible = true;
  int _lastScrollY = 0;
  Timer? _scrollDebounce;
  final List<String> _history = [];
  int _lastProgress = 0;
  Timer? _progressDebounce;

  // Pull-to-refresh controller
  PullToRefreshController? _pullToRefreshController;
  bool _isMediaSheetOpen = false;

  @override
  bool get wantKeepAlive => true; // Keep WebView alive when switching tabs

  InAppWebViewController? _getController(String? tabId) {
    if (tabId == null) return null;
    return _controllers[tabId];
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

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _initPullToRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tab = context.read<TabBloc>().state.activeTab;
      if (tab == null) return;
      final isEmptyTab = tab.url.isEmpty;
      _updateStatusBar(
        themeColor: isEmptyTab ? null : _tabThemeColors[tab.id],
        isIncognito: tab.isIncognito,
      );
    });
    // Handle deep link if exists
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      // Delay a bit for TabBloc to finish initializing
      Future.delayed(const Duration(milliseconds: 500), () {
        loadDeepLinkUrl(widget.initialUrl!);
      });
    }
  }

  void _initPullToRefresh() {
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),
      onRefresh: () async {
        final controller = _getController(
          context.read<TabBloc>().state.activeTab?.id,
        );
        if (controller != null) {
          await controller.reload();
        }
      },
    );
  }

  void loadDeepLinkUrl(String url) {
    final bloc = context.read<TabBloc>();
    final activeTab = bloc.state.activeTab;
    if (activeTab != null) {
      print('🔗 Loading deep link URL: $url');
      _addToNavHistory(activeTab.id, url);
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
    if (tab != null && tab.isIncognito) {
      return;
    }

    _history.remove(url);
    _history.insert(0, url);
    if (_history.length > 100) {
      _history.removeLast();
    }
    StorageService.saveHistory(_history);
  }

  final Map<String, List<String>> _navHistory = {};
  final Map<String, int> _navHistoryIndex = {};

  Future<bool> _canNavigateBack(String tabId) async {
    final controller = _getController(tabId);
    if (controller != null) {
      final canGoBack = await controller.canGoBack();
      if (canGoBack) return true;
    }
    if (!_navHistory.containsKey(tabId)) return false;
    final currentIndex = _navHistoryIndex[tabId] ?? -1;
    return currentIndex > 0;
  }

  Future<bool> _canNavigateForward(String tabId) async {
    final controller = _getController(tabId);
    if (controller != null) {
      final canGoForward = await controller.canGoForward();
      if (canGoForward) return true;
    }
    if (!_navHistory.containsKey(tabId)) return false;
    final history = _navHistory[tabId]!;
    final currentIndex = _navHistoryIndex[tabId] ?? -1;
    return currentIndex < history.length - 1;
  }

  void _handleNavigation(
    BuildContext context,
    String tabId,
    bool isForward,
  ) async {
    final controller = _getController(tabId);
    final bloc = context.read<TabBloc>();
    final activeTab = bloc.state.activeTab;
    if (activeTab == null) return;

    if (!_navHistory.containsKey(tabId)) {
      _navHistory[tabId] = [];
      _navHistoryIndex[tabId] = -1;
    }

    final history = _navHistory[tabId]!;
    final currentIndex = _navHistoryIndex[tabId]!;

    if (isForward) {
      if (currentIndex < history.length - 1) {
        final nextUrl = history[currentIndex + 1];
        _navHistoryIndex[tabId] = currentIndex + 1;
        bloc.add(UpdateTabEvent(activeTab.copyWith(url: nextUrl)));
        if (controller != null) {
          controller.loadUrl(urlRequest: URLRequest(url: WebUri(nextUrl)));
        }
      } else if (controller != null) {
        final canGoForward = await controller.canGoForward();
        if (canGoForward) {
          controller.goForward();
        }
      }
    } else {
      if (controller != null) {
        final canGoBack = await controller.canGoBack();
        if (canGoBack) {
          controller.goBack();
          return;
        }
      }

      if (currentIndex > 0) {
        final prevUrl = history[currentIndex - 1];
        _navHistoryIndex[tabId] = currentIndex - 1;
        bloc.add(UpdateTabEvent(activeTab.copyWith(url: prevUrl)));
        if (controller != null) {
          controller.loadUrl(urlRequest: URLRequest(url: WebUri(prevUrl)));
        }
      } else if (activeTab.url.isNotEmpty) {
        bloc.add(UpdateTabEvent(activeTab.copyWith(url: '')));
        _navHistoryIndex[tabId] = -1;
      }
    }
  }

  void _addToNavHistory(String tabId, String url) {
    if (!_navHistory.containsKey(tabId)) {
      _navHistory[tabId] = [];
      _navHistoryIndex[tabId] = -1;
    }

    final history = _navHistory[tabId]!;
    final currentIndex = _navHistoryIndex[tabId]!;
    if (currentIndex < history.length - 1) {
      _navHistory[tabId] = history.sublist(0, currentIndex + 1);
    }
    if (currentIndex < 0 || history[currentIndex] != url) {
      _navHistory[tabId]!.add(url);
      _navHistoryIndex[tabId] = _navHistory[tabId]!.length - 1;
    }
  }

  Future<void> _captureThumbnail(String tabId) async {
    try {
      final controller = _getController(tabId);

      if (controller != null) {
        // Use microtask to avoid blocking UI
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

      // Đợi frame render xong rồi mới chụp để đảm bảo context có sẵn
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted || key.currentContext == null) {
        return;
      }

      RenderObject? renderObject = key.currentContext!.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        return;
      }

      RenderRepaintBoundary boundary = renderObject as RenderRepaintBoundary;

      Future.microtask(() async {
        try {
          // Tăng pixelRatio để ảnh sắc nét hơn
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
        } catch (e) {
          // Silent fail
        }
      });
    } catch (e) {
      // Silent fail for thumbnail capture
    }
  }

  void _performSearch(dynamic activeTab) {
    final query = _searchController.text.trim();
    print(
      '🔍 _performSearch: query="$query", activeTab.url="${activeTab.url}"',
    );

    if (query.isNotEmpty) {
      final url = _formatUrl(query);
      print('🌐 Formatted URL: $url');
      _addToNavHistory(activeTab.id, url);

      final bloc = context.read<TabBloc>();
      bloc.add(UpdateTabEvent(activeTab.copyWith(url: url)));
      print('✅ UpdateTabEvent sent with URL: $url');

      final controller = _getController(activeTab.id);
      print('🔍 Controller: ${controller != null ? "EXISTS" : "NULL"}');

      if (controller != null) {
        controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
        print('✅ loadUrl called on existing controller');
      } else {
        print('⏳ Controller null, WebView will load when created');
      }

      setState(() {
        _isSearching = false;
      });
      _searchFocusNode.unfocus();
    }
  }

  void _handleScrollChange(int scrollY) {
    if ((scrollY - _lastScrollY).abs() < 5) return;

    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
      final shouldHide =
          scrollY > _lastScrollY && scrollY > 100 && _isToolbarVisible;
      final shouldShow = scrollY < _lastScrollY && !_isToolbarVisible;

      if (shouldHide || shouldShow) {
        setState(() {
          _isToolbarVisible = shouldShow;
        });
      }
      _lastScrollY = scrollY;
    });
  }

  void _resetScrollState() {
    setState(() {
      _lastScrollY = 0;
      _isToolbarVisible = true;
    });
  }

  // ── Status bar ──────────────────────────────────────────────────────────────

  void _updateStatusBar({Color? themeColor, required bool isIncognito}) {
    print('_updateStatusBar: $themeColor');
    final SystemUiOverlayStyle style;
    if (isIncognito) {
      style = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      );
    } else if (themeColor != null) {
      final isDark = themeColor.computeLuminance() < 0.179;
      style = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      );
    } else {
      style = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      );
    }
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  Future<void> _syncSystemUiFromWebPage({
    required InAppWebViewController controller,
    required String tabId,
    required bool isIncognito,
  }) async {
    print('_syncSystemUiFromWebPage');
    if (isIncognito) {
      _tabThemeColors.remove(tabId);
      _updateStatusBar(themeColor: null, isIncognito: true);
      return;
    }

    try {
      final jsResult = await controller.evaluateJavascript(
        source: '''
        (function() {
          function pickColor(el) {
            if (!el) return '';
            var bg = window.getComputedStyle(el).backgroundColor || '';
            if (!bg || bg === 'transparent' || bg === 'rgba(0, 0, 0, 0)') return '';
            return bg;
          }
          return pickColor(document.body) || pickColor(document.documentElement) || '';
        })();
      ''',
      );

      String cssColor = '';
      if (jsResult is String) {
        cssColor = jsResult;
      } else if (jsResult != null) {
        cssColor = jsResult.toString();
      }

      final color = _parseCssColor(cssColor);
      if (color != null) {
        _tabThemeColors[tabId] = color;
      } else {
        _tabThemeColors.remove(tabId);
      }

      _updateStatusBar(
        themeColor: _tabThemeColors[tabId],
        isIncognito: isIncognito,
      );
    } catch (_) {
      _updateStatusBar(
        themeColor: _tabThemeColors[tabId],
        isIncognito: isIncognito,
      );
    }
  }

  Color? _parseCssColor(String css) {
    css = css.trim();
    if (css.startsWith('"') && css.endsWith('"') && css.length >= 2) {
      css = css.substring(1, css.length - 1);
    }
    if (css.startsWith('#')) {
      final hex = css.substring(1);
      if (hex.length == 3) {
        final r = int.parse('${hex[0]}${hex[0]}', radix: 16);
        final g = int.parse('${hex[1]}${hex[1]}', radix: 16);
        final b = int.parse('${hex[2]}${hex[2]}', radix: 16);
        return Color.fromARGB(255, r, g, b);
      } else if (hex.length == 6) {
        final v = int.tryParse(hex, radix: 16);
        if (v != null) return Color(0xFF000000 | v);
      }
    }
    final rgb = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)').firstMatch(css);
    if (rgb != null) {
      return Color.fromARGB(
        255,
        int.parse(rgb.group(1)!),
        int.parse(rgb.group(2)!),
        int.parse(rgb.group(3)!),
      );
    }
    final rgba = RegExp(
      r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([0-9]*\.?[0-9]+)\)',
    ).firstMatch(css);
    if (rgba != null) {
      final alpha = double.tryParse(rgba.group(4)!) ?? 1.0;
      if (alpha <= 0) return null;
      return Color.fromARGB(
        (alpha * 255).round().clamp(0, 255),
        int.parse(rgba.group(1)!),
        int.parse(rgba.group(2)!),
        int.parse(rgba.group(3)!),
      );
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<TabBloc, TabState>(
      listenWhen: (prev, curr) =>
          prev.activeTab?.id != curr.activeTab?.id ||
          prev.isIncognitoMode != curr.isIncognitoMode ||
          (prev.activeTab?.url.isEmpty ?? true) !=
              (curr.activeTab?.url.isEmpty ?? true),
      listener: (context, state) {
        final tab = state.activeTab;
        if (tab == null) return;
        // Khi đổi tab hoặc về empty page → reset status bar style
        final isEmptyTab = tab.url.isEmpty;
        _updateStatusBar(
          themeColor: isEmptyTab ? null : _tabThemeColors[tab.id],
          isIncognito: tab.isIncognito,
        );
      },
      child: BlocBuilder<TabBloc, TabState>(
        buildWhen: (previous, current) {
          final prevTab = previous.activeTab;
          final currTab = current.activeTab;

          if (prevTab?.id != currTab?.id) return true;
          if (previous.tabs.length != current.tabs.length) return true;
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

          final isIncognito = activeTab.isIncognito ?? false;

          return Scaffold(
            // Scaffold trong suốt để content vẽ dưới system bars
            backgroundColor: isIncognito
                ? const Color(0xFF1A1A2E)
                : Colors.white,
            body: Column(
              children: [
                // Page content — full screen, không SafeArea ở đây
                // EmptyPage tự xử lý SafeArea bên trong
                Expanded(
                  child: _PageContentWrapper(
                    activeTab: activeTab,
                    tabState: tabState,
                    isToolbarVisible: _isToolbarVisible,
                    buildPageContent: _buildPageContent,
                  ),
                ),
                // Bottom bar — bao gồm padding cho navigation bar
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _isToolbarVisible
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ProgressBarWrapper(activeTabId: activeTab.id),
                            RepaintBoundary(
                              child: _BottomBarWrapper(
                                activeTabId: activeTab.id,
                                controller: _getController(activeTab.id),
                                onShowTabs: () => _showTabsSheet(context),
                                onAddressBarTap: () => _showSearchPage(context),
                                onShowHistory: () => _showHistorySheet(context),
                                onShowDownload: () =>
                                    _showDownloadSheet(context),
                                onShowMedia: () => _showMediaSheet(context),
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
                                  final currentTab = bloc.state.activeTab;
                                  if (currentTab != null) {
                                    _performSearch(currentTab);
                                  }
                                },
                                onBack: () => _handleNavigation(
                                  context,
                                  activeTab.id,
                                  false,
                                ),
                                onForward: () => _handleNavigation(
                                  context,
                                  activeTab.id,
                                  true,
                                ),
                                canGoBack: () => _canNavigateBack(activeTab.id),
                                canGoForward: () =>
                                    _canNavigateForward(activeTab.id),
                              ),
                            ),
                          ],
                        )
                      : _MiniUrlBarWrapper(
                          activeTabId: activeTab.id,
                          controller: _getController(activeTab.id),
                          onTap: () => _showSearchPage(context),
                        ),
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
    return Stack(
      children: tabState.tabs.map((tab) {
        final isActive = tab.id == activeTab.id;

        if (tab.url.isEmpty) {
          return Offstage(
            offstage: !isActive,
            child: RepaintBoundary(
              key: ValueKey('empty_boundary_${tab.id}'),
              child: EmptyPage(
                key: ValueKey('empty_${tab.id}'),
                activeTab: tab,
                onSearchBarTap: () => _showSearchPage(context),
                onQuickAccessTap: (url) {
                  _resetScrollState();
                  final formatted = _formatUrl(url);
                  _addToNavHistory(tab.id, formatted);
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
            ),
          );
        }

        return Offstage(
          offstage: !isActive,
          child: WebViewPage(
            key: ValueKey('webview_${tab.id}'),
            activeTab: tab,
            controller: _getController(tab.id),
            pullToRefreshController: _pullToRefreshController,
            onWebViewCreated: (controller) =>
                _setController(tab.id, controller),
            onUpdateVisitedHistory: (controller, url, isReload) {
              final bloc = context.read<TabBloc>();
              final currentTab = bloc.state.tabs.firstWhere(
                (t) => t.id == tab.id,
                orElse: () => tab,
              );
              if (currentTab != null) {
                final urlStr = url?.toString() ?? '';
                if (urlStr.isNotEmpty &&
                    !urlStr.startsWith('intent://') &&
                    !_isExternalUrl(urlStr)) {
                  if (currentTab.url != urlStr) {
                    bloc.add(
                      UpdateTabEvent(
                        currentTab.copyWith(url: urlStr),
                        skipCache: true,
                      ),
                    );
                  }
                }
              }
            },
            onUrlUpdated: (newUrl) {
              final bloc = context.read<TabBloc>();
              final currentTab = bloc.state.tabs.firstWhere(
                (t) => t.id == tab.id,
                orElse: () => tab,
              );
              if (currentTab != null && newUrl.isNotEmpty) {
                bloc.add(
                  UpdateTabEvent(
                    currentTab.copyWith(url: newUrl),
                    skipCache: false,
                  ),
                );
              }
            },
            onLoadStart: (controller, url) {
              _resetScrollState();
              final bloc = context.read<TabBloc>();
              final currentTab = bloc.state.tabs.firstWhere(
                (t) => t.id == tab.id,
                orElse: () => tab,
              );
              if (currentTab != null) {
                final urlStr = url?.toString() ?? '';
                if (!urlStr.startsWith('intent://') &&
                    !_isExternalUrl(urlStr)) {
                  if (currentTab.url != urlStr) {
                    bloc.add(
                      UpdateTabEvent(
                        currentTab.copyWith(url: urlStr),
                        skipCache: true,
                      ),
                    );
                  }
                }
              }
            },
            onLoadStop: (controller, url) async {
              final bloc = context.read<TabBloc>();
              final currentTab = bloc.state.tabs.firstWhere(
                (t) => t.id == tab.id,
                orElse: () => tab,
              );
              if (currentTab != null) {
                final urlStr = url?.toString() ?? '';
                if (url != null &&
                    urlStr.isNotEmpty &&
                    !urlStr.startsWith('intent://') &&
                    !_isExternalUrl(urlStr)) {
                  if (tab.url.isNotEmpty && isActive) {
                    await _syncSystemUiFromWebPage(
                      controller: controller,
                      tabId: tab.id,
                      isIncognito: currentTab.isIncognito,
                    );
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
                    final fallbackTitle = uri?.host ?? _formatUrlTitle(urlStr);
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
                    _captureThumbnail(tab.id);
                    _addToHistory(urlStr);
                  });
                }
              }
            },
            onTitleChanged: (controller, title) {
              final bloc = context.read<TabBloc>();
              final currentTab = bloc.state.tabs.firstWhere(
                (t) => t.id == tab.id,
                orElse: () => tab,
              );
              if (currentTab != null &&
                  title != null &&
                  title.isNotEmpty &&
                  currentTab.title != title) {
                bloc.add(
                  UpdateTabEvent(
                    currentTab.copyWith(title: title),
                    skipCache: true,
                  ),
                );
              }
            },
            onProgressChanged: (controller, progress) {
              // Tăng threshold để giảm số lần update - chỉ update khi thay đổi 20%+
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
                if (currentTab != null) {
                  bloc.add(
                    UpdateTabEvent(
                      currentTab.copyWith(
                        loadProgress: progress,
                        isLoading: progress < 100,
                      ),
                      skipCache: true,
                    ),
                  );
                }
              });
            },
            onScrollChanged: (y) {
              _handleScrollChange(y);
            },
            onSwipeBack: () {
              _handleNavigation(context, tab.id, false);
            },
            onSwipeForward: () {
              _handleNavigation(context, tab.id, true);
            },
          ),
        );
      }).toList(),
    );
  }

  void _showTabsSheet(BuildContext context) {
    if (_isSearching) {
      setState(() {
        _isSearching = false;
      });
    }
    _searchFocusNode.unfocus();

    final bloc = context.read<TabBloc>();
    final activeTabId = bloc.state.activeTab?.id;
    if (activeTabId != null) {
      _captureThumbnail(activeTabId);
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
            final controller = _controllers.remove(tabId);
            if (controller != null) {}
            // Clear search khi đóng tab
            if (_isSearching) {
              _searchController.clear();
              setState(() {
                _isSearching = false;
              });
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
          onAddTab: () {
            Navigator.pop(sheetContext);
          },
        ),
      ),
    ).then((_) {
      _refreshWebViewForInteraction();
    });
  }

  void _refreshWebViewForInteraction() {}

  void _showHistorySheet(BuildContext context) {
    if (_isSearching) {
      setState(() {
        _isSearching = false;
      });
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
          final currentTab = bloc.state.activeTab;
          if (currentTab != null) {
            _addToNavHistory(currentTab.id, url);
            bloc.add(UpdateTabEvent(currentTab.copyWith(url: url)));
            final controller = _getController(currentTab.id);
            if (controller != null) {
              controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
            }
          }
        },
        onClearHistory: () {
          setState(() {
            _history.clear();
          });
          StorageService.saveHistory(_history);
        },
        onRemoveHistory: (url) {
          setState(() {
            _history.remove(url);
          });
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
    final activeTab = bloc.state.activeTab;

    final controller = _getController(activeTab?.id);

    if (controller == null) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('No active tab')),
      // );
      return;
    }

    // Get loaded resources from active tab
    final loadedResources = activeTab?.loadedResources ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _buildMediaSheet(
        sheetContext,
        context,
        controller,
        loadedResources,
        0.6,
      ),
    ).then((_) => _refreshWebViewForInteraction());
  }

  void _showMediaSheetExpanded(
    BuildContext context,
    InAppWebViewController controller,
    List<LoadedResource> loadedResources,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _buildMediaSheet(
        sheetContext,
        context,
        controller,
        loadedResources,
        0.9,
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
    final isExpanded = heightFactor > 0.7;
    return BlocProvider.value(
      value: parentContext.read<DownloadBloc>(),
      child: Container(
        height: MediaQuery.of(parentContext).size.height * heightFactor,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            // Drag handle
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity!.abs() > 300) {
                  Navigator.pop(sheetContext);
                  if (details.primaryVelocity! < 0 && !isExpanded) {
                    _showMediaSheetExpanded(
                      parentContext,
                      controller,
                      loadedResources,
                    );
                  } else if (details.primaryVelocity! > 0 && isExpanded) {
                    showModalBottomSheet(
                      context: parentContext,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (sheetContext) => _buildMediaSheet(
                        sheetContext,
                        parentContext,
                        controller,
                        loadedResources,
                        0.6,
                      ),
                    );
                  }
                }
              },
              child: Container(
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
            ),
            // Media gallery content
            Expanded(
              child: MediaGallerySheet(
                controller: controller,
                loadedResources: loadedResources,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchPage(BuildContext context) {
    final bloc = context.read<TabBloc>();
    final searchBloc = context.read<SearchBloc>();
    final currentTab = bloc.state.activeTab;
    if (currentTab == null) return;

    if (_isSearching) {
      setState(() {
        _isSearching = false;
      });
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
            skipHistory: currentTab
                .isIncognito, // Skip saving search history for incognito tabs
            onSearch: (query) {
              final url = SearchService.formatInput(query);
              _addToNavHistory(currentTab.id, url);
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

  String _formatUrl(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    if (input.contains('.') && !input.contains(' ')) {
      return 'https://$input';
    }
    return 'https://www.google.com/search?q=${Uri.encodeComponent(input)}';
  }

  String _formatUrlTitle(String url) {
    if (url.startsWith('https://')) {
      url = url.substring(8);
    } else if (url.startsWith('http://')) {
      url = url.substring(7);
    }
    final parts = url.split('/');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return url;
  }

  /* ================= HELPER METHODS ================= */

  static String? _scheme(String url) {
    final i = url.indexOf('://');
    return i == -1 ? null : url.substring(0, i).toLowerCase();
  }

  static bool _isExternalUrl(String url) {
    final scheme = _scheme(url.toLowerCase());
    const externalSchemes = {
      'googlechrome',
      'chrome',
      'firefox',
      'edge',
      'opera',
    };
    return scheme != null && externalSchemes.contains(scheme);
  }
}

class _BottomBarWrapper extends StatelessWidget {
  final String activeTabId;
  final InAppWebViewController? controller;
  final VoidCallback onShowTabs;
  final VoidCallback onAddressBarTap;
  final VoidCallback onShowHistory;
  final VoidCallback onShowDownload;
  final VoidCallback onShowMedia;

  final bool isSearching;
  final bool isMediaSheetOpen;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSearch;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final Future<bool> Function() canGoBack;
  final Future<bool> Function() canGoForward;

  const _BottomBarWrapper({
    required this.activeTabId,
    required this.controller,
    required this.onShowTabs,
    required this.onAddressBarTap,
    required this.onShowHistory,
    required this.onShowDownload,
    required this.onShowMedia,
    required this.isSearching,
    required this.isMediaSheetOpen,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearch,
    required this.onBack,
    required this.onForward,
    required this.canGoBack,
    required this.canGoForward,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      buildWhen: (previous, current) {
        final prevActiveTab = previous.activeTab;
        final currActiveTab = current.activeTab;
        if (previous.isIncognitoMode != current.isIncognitoMode) {
          return true;
        }

        // Nếu activeTabId khác với activeTab hiện tại, tìm trong list tabs
        if (prevActiveTab?.id != activeTabId ||
            currActiveTab?.id != activeTabId) {
          final prevTab = previous.tabs.firstWhere(
            (t) => t.id == activeTabId,
            orElse: () => previous.activeTab!,
          );
          final currTab = current.tabs.firstWhere(
            (t) => t.id == activeTabId,
            orElse: () => current.activeTab!,
          );
          return prevTab.url != currTab.url ||
              prevTab.title != currTab.title ||
              prevTab.isLoading != currTab.isLoading ||
              previous.tabs.length != current.tabs.length;
        }

        return prevActiveTab?.url != currActiveTab?.url ||
            prevActiveTab?.title != currActiveTab?.title ||
            prevActiveTab?.isLoading != currActiveTab?.isLoading ||
            previous.tabs.length != current.tabs.length;
      },
      builder: (context, tabState) {
        final activeTab = tabState.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => tabState.activeTab!,
        );
        return BottomBar(
          activeTab: activeTab,
          tabState: tabState,
          controller: controller,
          onShowTabs: onShowTabs,
          onAddressBarTap: onAddressBarTap,
          onShowHistory: onShowHistory,
          onShowDownload: onShowDownload,
          onShowMedia: onShowMedia,
          isSearching: isSearching,
          isMediaSheetOpen: isMediaSheetOpen,
          searchController: searchController,
          searchFocusNode: searchFocusNode,
          onSearch: onSearch,
          onBack: onBack,
          onForward: onForward,
          canGoBack: canGoBack,
          canGoForward: canGoForward,
        );
      },
    );
  }
}

class _MiniUrlBarWrapper extends StatelessWidget {
  final String activeTabId;
  final InAppWebViewController? controller;
  final VoidCallback onTap;

  const _MiniUrlBarWrapper({
    required this.activeTabId,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      buildWhen: (previous, current) {
        final prevTab = previous.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => previous.activeTab!,
        );
        final currTab = current.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => current.activeTab!,
        );
        return prevTab.url != currTab.url;
      },
      builder: (context, tabState) {
        final activeTab = tabState.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => tabState.activeTab!,
        );
        return MiniUrlBar(
          activeTab: activeTab,
          controller: controller,
          onTap: onTap,
        );
      },
    );
  }
}

class _ProgressBarWrapper extends StatelessWidget {
  final String activeTabId;

  const _ProgressBarWrapper({required this.activeTabId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      buildWhen: (previous, current) {
        final prevTab = previous.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => previous.activeTab!,
        );
        final currTab = current.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => current.activeTab!,
        );

        if (prevTab.isLoading != currTab.isLoading) return true;

        if (currTab.isLoading) {
          final progressDelta = (currTab.loadProgress - prevTab.loadProgress)
              .abs();
          return progressDelta >= 10 ||
              currTab.loadProgress == 100 ||
              currTab.loadProgress == 0;
        }

        return false;
      },
      builder: (context, tabState) {
        final activeTab = tabState.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => tabState.activeTab!,
        );

        if (!activeTab.isLoading) {
          return const SizedBox.shrink();
        }
        final isIncognito = activeTab.isIncognito ?? false;

        return TweenAnimationBuilder<double>(
          key: ValueKey(activeTab.loadProgress),
          tween: Tween(begin: 0, end: activeTab.loadProgress / 100),
          duration: const Duration(milliseconds: 100),
          builder: (context, value, child) {
            return SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isIncognito ? Colors.white70 : const Color(0xFF2196F3),
                ),
                minHeight: 2,
              ),
            );
          },
        );
      },
    );
  }
}

class _PageContentWrapper extends StatelessWidget {
  final dynamic activeTab;
  final TabState tabState;
  final bool isToolbarVisible;
  final Widget Function(BuildContext, dynamic, TabState) buildPageContent;

  const _PageContentWrapper({
    required this.activeTab,
    required this.tabState,
    required this.isToolbarVisible,
    required this.buildPageContent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: _buildBottomPadding(context),
      child: buildPageContent(context, activeTab, tabState),
    );
  }

  EdgeInsets _buildBottomPadding(BuildContext context) {
    return EdgeInsets.zero;
  }
}
