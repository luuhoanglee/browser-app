import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../data/repositories/tab_repository_impl.dart';
import '../../../data/services/storage_service.dart';
import '../../../features/tabs/bloc/tab_bloc.dart';
import '../../../features/tabs/bloc/tab_event.dart';
import '../../../features/tabs/bloc/tab_state.dart';
import 'models/quick_access_item.dart';
import 'widgets/mini_url_bar.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/history_sheet.dart';
import '../../../features/tabs/widgets/empty_page.dart';
import '../../../features/webview/widgets/webview_page.dart';
import '../../../features/tabs/widgets/tabs_sheet.dart';
import '../../../features/search/widgets/search_page.dart';
import '../../../features/search/bloc/search_bloc.dart';
import '../../../features/search/bloc/search_event.dart';
import '../../../features/search/search_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => TabBloc(TabRepositoryImpl())),
        BlocProvider(create: (context) => SearchBloc()),
      ],
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final Map<String, InAppWebViewController> _controllers = {};
  final Map<String, GlobalKey> _emptyPageKeys = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _isToolbarVisible = true;
  int _lastScrollY = 0;
  Timer? _scrollDebounce;
  final List<String> _history = [];
  int _lastProgress = 0;
  Timer? _progressDebounce;

  // Quick Access Items
  static const List<QuickAccessItem> _quickAccessItems = [
    QuickAccessItem(
      title: 'Google',
      url: 'google.com',
      icon: Icons.search,
      color: Colors.blue,
    ),
    QuickAccessItem(
      title: 'YouTube',
      url: 'youtube.com',
      icon: Icons.play_circle_filled,
      color: Colors.red,
    ),
    QuickAccessItem(
      title: 'Facebook',
      url: 'facebook.com',
      icon: Icons.facebook,
      color: Colors.blue,
    ),
    QuickAccessItem(
      title: 'GitHub',
      url: 'github.com',
      icon: Icons.code,
      color: Colors.grey,
    ),
    QuickAccessItem(
      title: 'Twitter',
      url: 'twitter.com',
      icon: Icons.alternate_email,
      color: Colors.lightBlue,
    ),
    QuickAccessItem(
      title: 'Reddit',
      url: 'reddit.com',
      icon: Icons.forum,
      color: Colors.orange,
    ),
    QuickAccessItem(
      title: 'Wikipedia',
      url: 'wikipedia.org',
      icon: Icons.menu_book,
      color: Colors.grey,
    ),
    QuickAccessItem(
      title: 'Amazon',
      url: 'amazon.com',
      icon: Icons.shopping_cart,
      color: Colors.orange,
    ),
  ];

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
    // Nếu URL đã có trong history, xóa nó trước
    _history.remove(url);
    // Thêm vào đầu danh sách
    _history.insert(0, url);
    // Giới hạn số lượng history
    if (_history.length > 100) {
      _history.removeLast();
    }
    // Lưu vào cache (không await để không blocking)
    StorageService.saveHistory(_history);
    // Chỉ setState khi cần thiết
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _captureThumbnail(String tabId) async {
    try {
      final controller = _getController(tabId);

      // Nếu có controller (tab có URL), chụp screenshot từ WebView
      if (controller != null) {
        final Uint8List? screenshot = await controller.takeScreenshot();

        if (screenshot != null) {
          final bloc = context.read<TabBloc>();
          final tab = bloc.state.tabs.firstWhere((t) => t.id == tabId);
          bloc.add(UpdateTabEvent(tab.copyWith(thumbnail: screenshot), skipCache: true));
          return;
        }
      }

      // Nếu không có controller (empty page), chụp từ RepaintBoundary
      final key = _getEmptyPageKey(tabId);
      if (key.currentContext == null) {
        return;
      }

      RenderObject? renderObject = key.currentContext!.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        return;
      }

      RenderRepaintBoundary boundary = renderObject as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 0.3);

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      final bloc = context.read<TabBloc>();
      final tab = bloc.state.tabs.firstWhere((t) => t.id == tabId);
      bloc.add(UpdateTabEvent(tab.copyWith(thumbnail: pngBytes), skipCache: true));
    } catch (e) {
      // Silent fail for thumbnail capture
    }
  }

  void _performSearch(dynamic activeTab) {
    final query = _searchController.text.trim();
    print('🔍 _performSearch: query="$query", activeTab.url="${activeTab.url}"');

    if (query.isNotEmpty) {
      final url = _formatUrl(query);
      print('🌐 Formatted URL: $url');

      final bloc = context.read<TabBloc>();
      bloc.add(UpdateTabEvent(activeTab.copyWith(url: url)));
      print('✅ UpdateTabEvent sent with URL: $url');

      final controller = _getController(activeTab.id);
      print('🔍 Controller: ${controller != null ? "EXISTS" : "NULL"}');

      if (controller != null) {
        // WebView đã tồn tại, load URL trực tiếp
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
    // Debounce scroll changes để tránh quá nhiều setState
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
      final shouldHide = scrollY > _lastScrollY && scrollY > 100 && _isToolbarVisible;
      final shouldShow = scrollY < _lastScrollY && !_isToolbarVisible;

      if (shouldHide || shouldShow) {
        setState(() {
          _isToolbarVisible = shouldShow;
        });
      }
      _lastScrollY = scrollY;
    });
  }

  // Reset scroll state khi chuyển tab
  void _resetScrollState() {
    setState(() {
      _lastScrollY = 0;
      _isToolbarVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      buildWhen: (previous, current) {
        final prevTab = previous.activeTab;
        final currTab = current.activeTab;

        if (prevTab?.id != currTab?.id) return true; // Chuyển tab
        if (previous.tabs.length != current.tabs.length) return true; // Thêm/xoá tab

        final prevUrlEmpty = prevTab?.url.isEmpty ?? true;
        final currUrlEmpty = currTab?.url.isEmpty ?? true;
        if (prevUrlEmpty != currUrlEmpty) return true;
        return false;
      },
      builder: (context, tabState) {
        final activeTab = tabState.activeTab;
        if (activeTab == null) {
          return const Scaffold(
            body: SizedBox.shrink(),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                _buildPageContent(context, activeTab, tabState),
                // Bottom bar - Address bar and navigation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: 0,
                  right: 0,
                  bottom: _isToolbarVisible ? 0 : -150,
                  child: RepaintBoundary(
                    child: _BottomBarWrapper(
                      activeTabId: activeTab.id,
                      controller: _getController(activeTab.id),
                      onShowTabs: () => _showTabsSheet(context),
                      onAddressBarTap: () => _showSearchPage(context),
                      onShowHistory: () => _showHistorySheet(context),
                      isSearching: _isSearching,
                      searchController: _searchController,
                      searchFocusNode: _searchFocusNode,
                      onSearch: (query) {
                        _searchController.text = query;
                        // Lưu vào search history
                        context.read<SearchBloc>().add(PerformSearchEvent(query));
                        final bloc = context.read<TabBloc>();
                        final currentTab = bloc.state.activeTab;
                        if (currentTab != null) {
                          _performSearch(currentTab);
                        }
                      },
                    ),
                  ),
                ),
                // Mini URL bar - hiển thị dài hết màn hình khi scroll
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: 0,
                  right: 0,
                  bottom: _isToolbarVisible ? -50 : 0,
                  child: _MiniUrlBarWrapper(
                    activeTabId: activeTab.id,
                    controller: _getController(activeTab.id),
                    onTap: () => _showSearchPage(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageContent(BuildContext context, dynamic activeTab, TabState tabState) {
    print('🔨 _buildPageContent: tabId=${activeTab.id}, url="${activeTab.url}", isEmpty=${activeTab.url.isEmpty}');

    if (activeTab.url.isEmpty) {
      print('✅ Showing EmptyPage for tab ${activeTab.id}');
      return RepaintBoundary(
        key: _getEmptyPageKey(activeTab.id),
        child: EmptyPage(
          activeTab: activeTab,
          quickAccessItems: _quickAccessItems,
          onQuickAccessTap: (item) {
            _resetScrollState();
            final url = _formatUrl(item.url);

            final bloc = context.read<TabBloc>();
            bloc.add(UpdateTabEvent(activeTab.copyWith(url: url)));

            print('🔗 Quick Access: URL = $url, current controller = ${_getController(activeTab.id) != null ? "EXISTS" : "NULL"}');

            // Nếu controller đã tồn tại, load ngay
            // Nếu chưa, WebView sẽ tự load khi được tạo với initialUrlRequest
            final controller = _getController(activeTab.id);
            if (controller != null) {
              controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
            }
          },
        ),
      );
    }

    print('✅ Showing WebViewPage for tab ${activeTab.id}');
    return RepaintBoundary(
      key: ValueKey('webview_${activeTab.id}'),
      child: WebViewPage(
        activeTab: activeTab,
        controller: _getController(activeTab.id),
        onWebViewCreated: (controller) => _setController(activeTab.id, controller),
        onLoadStart: (controller, url) {
          _resetScrollState();
          final bloc = context.read<TabBloc>();
          final tab = bloc.state.activeTab;
          if (tab != null) {
            bloc.add(UpdateTabEvent(tab.copyWith(isLoading: true, url: url?.toString() ?? '')));
          }
        },
        onLoadStop: (controller, url) async {
          final bloc = context.read<TabBloc>();
          final tab = bloc.state.activeTab;
          if (tab != null) {
            bloc.add(UpdateTabEvent(tab.copyWith(isLoading: false, url: url?.toString() ?? '')));
            // Capture thumbnail after page loads
            if (url != null && url.toString().isNotEmpty) {
              await Future.delayed(const Duration(milliseconds: 500));
              _captureThumbnail(activeTab.id);
              // Thêm vào history
              final urlStr = url.toString();
              _addToHistory(urlStr);
            }
          }
        },
        onTitleChanged: (controller, title) {
          final bloc = context.read<TabBloc>();
          final tab = bloc.state.activeTab;
          if (tab != null && title != null) {
            bloc.add(UpdateTabEvent(tab.copyWith(title: title), skipCache: true));
          }
        },
        onProgressChanged: (controller, progress) {
          // Throttle progress updates để giảm số lần rebuild
          // Chỉ update khi progress thay đổi ít nhất 10% hoặc khi hoàn thành (100%)
          final shouldUpdate = (progress - _lastProgress).abs() >= 10 ||
              progress == 100 ||
              progress == 0;

          if (!shouldUpdate) return;

          _lastProgress = progress;

          // Debounce nhanh để tránh quá nhiều update liên tiếp
          _progressDebounce?.cancel();
          _progressDebounce = Timer(const Duration(milliseconds: 50), () {
            final bloc = context.read<TabBloc>();
            final tab = bloc.state.activeTab;
            if (tab != null) {
              bloc.add(UpdateTabEvent(
                tab.copyWith(loadProgress: progress, isLoading: progress < 100),
              ));
            }
          });
        },
        onScrollChanged: (y) {
          _handleScrollChange(y);
        },
      ),
    );
  }

  void _showTabsSheet(BuildContext context) {
    setState(() {
      _isSearching = false;
      _searchFocusNode.unfocus();
    });

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
            // Clear search khi đóng tab
            _searchController.clear();
            setState(() {
              _isSearching = false;
            });
          },
          onSelectTab: (tabId) {
            context.read<TabBloc>().add(SelectTabEvent(tabId));
            Navigator.pop(sheetContext);
          },
          onAddTab: () {
            // Đóng sheet sau khi tạo tab mới
            Navigator.pop(sheetContext);
          },
        ),
      ),
    );
  }

  void _showHistorySheet(BuildContext context) {
    setState(() {
      _isSearching = false;
      _searchFocusNode.unfocus();
    });

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
    );
  }

  void _showSearchPage(BuildContext context) {
    final bloc = context.read<TabBloc>();
    final searchBloc = context.read<SearchBloc>();
    final currentTab = bloc.state.activeTab;
    if (currentTab == null) return;

    setState(() {
      _isSearching = false;
      _searchFocusNode.unfocus();
    });

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
            if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
              Navigator.pop(sheetContext);
            }
          },
          child: SearchPage(
            initialUrl: currentTab.url.isNotEmpty ? currentTab.url : null,
            onSearch: (query) {
              // Dùng formatUrl để tự động detect URL hoặc search query
              final url = SearchService.formatUrl(query);
              bloc.add(UpdateTabEvent(currentTab.copyWith(url: url)));
              final controller = _getController(currentTab.id);
              if (controller != null) {
                controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
              }
            },
          ),
        ),
      ),
    );
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
}

// Widget wrapper riêng để rebuild chỉ khi URL/title thay đổi
class _BottomBarWrapper extends StatelessWidget {
  final String activeTabId;
  final InAppWebViewController? controller;
  final VoidCallback onShowTabs;
  final VoidCallback onAddressBarTap;
  final VoidCallback onShowHistory;
  final bool isSearching;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSearch;

  const _BottomBarWrapper({
    required this.activeTabId,
    required this.controller,
    required this.onShowTabs,
    required this.onAddressBarTap,
    required this.onShowHistory,
    required this.isSearching,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      buildWhen: (previous, current) {
        // Rebuild khi URL, title, isLoading, loadProgress, hoặc số lượng tabs thay đổi
        // Ưu tiên so sánh activeTab vì onProgressChanged chỉ cập nhật activeTab
        final prevActiveTab = previous.activeTab;
        final currActiveTab = current.activeTab;

        // Nếu activeTabId khác với activeTab hiện tại, tìm trong list tabs
        if (prevActiveTab?.id != activeTabId || currActiveTab?.id != activeTabId) {
          final prevTab = previous.tabs.firstWhere((t) => t.id == activeTabId, orElse: () => previous.activeTab!);
          final currTab = current.tabs.firstWhere((t) => t.id == activeTabId, orElse: () => current.activeTab!);
          return prevTab.url != currTab.url ||
                 prevTab.title != currTab.title ||
                 prevTab.isLoading != currTab.isLoading ||
                 prevTab.loadProgress != currTab.loadProgress ||
                 previous.tabs.length != current.tabs.length;
        }

        // So sánh activeTab (trường hợp phổ biến nhất)
        return prevActiveTab?.url != currActiveTab?.url ||
               prevActiveTab?.title != currActiveTab?.title ||
               prevActiveTab?.isLoading != currActiveTab?.isLoading ||
               prevActiveTab?.loadProgress != currActiveTab?.loadProgress ||
               previous.tabs.length != current.tabs.length;
      },
      builder: (context, tabState) {
        final activeTab = tabState.tabs.firstWhere((t) => t.id == activeTabId, orElse: () => tabState.activeTab!);
        return BottomBar(
          activeTab: activeTab,
          tabState: tabState,
          controller: controller,
          onShowTabs: onShowTabs,
          onAddressBarTap: onAddressBarTap,
          onShowHistory: onShowHistory,
          isSearching: isSearching,
          searchController: searchController,
          searchFocusNode: searchFocusNode,
          onSearch: onSearch,
          // Truyền activeTab để BottomBar tự lấy isLoading và loadProgress
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
        final prevTab = previous.tabs.firstWhere((t) => t.id == activeTabId, orElse: () => previous.activeTab!);
        final currTab = current.tabs.firstWhere((t) => t.id == activeTabId, orElse: () => current.activeTab!);
        // Chỉ rebuild khi URL thay đổi
        return prevTab.url != currTab.url;
      },
      builder: (context, tabState) {
        final activeTab = tabState.tabs.firstWhere((t) => t.id == activeTabId, orElse: () => tabState.activeTab!);
        return MiniUrlBar(
          activeTab: activeTab,
          controller: controller,
          onTap: onTap,
        );
      },
    );
  }
}
