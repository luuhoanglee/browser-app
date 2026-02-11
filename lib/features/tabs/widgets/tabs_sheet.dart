import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/tab_bloc.dart';
import '../bloc/tab_state.dart';
import '../bloc/tab_event.dart';

class TabsSheet extends StatefulWidget {
  final Function(String) onCloseTab;
  final Function(String) onSelectTab;
  final VoidCallback onAddTab;

  const TabsSheet({
    super.key,
    required this.onCloseTab,
    required this.onSelectTab,
    required this.onAddTab,
  });

  @override
  State<TabsSheet> createState() => _TabsSheetState();
}

class _TabsSheetState extends State<TabsSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll đến active tab sau khi widget được build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveTab();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveTab() {
    final tabState = context.read<TabBloc>().state;
    final activeTabId = tabState.activeTab?.id;
    if (activeTabId == null) return;

    // Tìm index của active tab
    final activeIndex = tabState.tabs.indexWhere((tab) => tab.id == activeTabId);
    if (activeIndex == -1) return;

    // Tính vị trí scroll (2 cột, mỗi item có spacing)
    final crossAxisCount = 2;
    final mainAxisSpacing = 8.0;
    final itemHeight = (MediaQuery.of(context).size.width - 32 - 8) / 2 / 0.75; // padding + spacing + childAspectRatio

    // Scroll đến vị trí của active tab với một chút offset để nó hiển thị ở giữa
    final targetPosition = (activeIndex ~/ crossAxisCount) * (itemHeight + mainAxisSpacing);
    final offset = max(0.0, targetPosition - 100); // Offset để active tab không bị che

    _scrollController.animateTo(
      offset.toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      builder: (context, tabState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${tabState.tabs.length} Tabs',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.read<TabBloc>().add(AddTabEvent());
                        widget.onAddTab(); // Đóng sheet sau khi tạo tab mới
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, size: 20, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    controller: _scrollController,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: tabState.tabs.length,
                    itemBuilder: (context, index) {
                      final tab = tabState.tabs[index];
                      final isActive = tab.id == tabState.activeTab?.id;

                      // Wrap with RepaintBoundary to isolate repaints
                      return RepaintBoundary(
                        child: _TabCard(
                          key: ValueKey(tab.id),
                          tab: tab,
                          isActive: isActive,
                          onTap: () => widget.onSelectTab(tab.id),
                          onClose: () => widget.onCloseTab(tab.id),
                          canClose: tabState.tabs.isNotEmpty,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Done button
              Container(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Separate const widget for tab card to optimize rebuilds
class _TabCard extends StatelessWidget {
  final dynamic tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final bool canClose;

  const _TabCard({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.canClose,
  });

  @override
  Widget build(BuildContext context) {
    return TabCardBuilder.buildTabCard(
      tab: tab,
      isActive: isActive,
      onTap: onTap,
      onClose: onClose,
      canClose: canClose,
    );
  }
}

// Static method for building tab card - can be reused anywhere
class TabCardBuilder {
  static Widget buildTabCard({
    Key? key,
    required dynamic tab,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onClose,
    required bool canClose,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: key,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
          border: isActive
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[100],
                          child: tab.thumbnail != null
                              ? Image.memory(
                                  tab.thumbnail!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true, // Prevent flicker
                                )
                              : _buildEmptyThumbnail(tab),
                        ),
                      ),
                      if (isActive)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Info
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tab.title.isNotEmpty ? tab.title : 'New Tab',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTabUrl(tab.url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (canClose)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.close, size: 14, color: Colors.grey[700]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildEmptyThumbnail(dynamic tab) {
    final color = _getColorFromUrl(tab.url);

    String firstLetter = 'N';
    if (tab.url.isNotEmpty) {
      final displayUrl = _formatDisplayUrl(tab.url);
      if (displayUrl.isNotEmpty) {
        firstLetter = displayUrl[0].toUpperCase();
      }
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.url.isEmpty ? Icons.add_circle_outline : Icons.web,
              size: 36,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 8),
            Text(
              tab.url.isEmpty ? 'New Tab' : firstLetter,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _getColorFromUrl(String url) {
    if (url.isEmpty) {
      return Colors.blue;
    }

    final hash = url.hashCode;
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }

  static String _formatTabUrl(String url) {
    if (url.startsWith('https://')) {
      url = url.substring(8);
    } else if (url.startsWith('http://')) {
      url = url.substring(7);
    }
    if (url.length > 25) {
      return '${url.substring(0, 25)}...';
    }
    return url;
  }

  static String _formatDisplayUrl(String url) {
    if (url.startsWith('https://')) {
      return url.substring(8);
    } else if (url.startsWith('http://')) {
      return url.substring(7);
    }
    return url;
  }
}
