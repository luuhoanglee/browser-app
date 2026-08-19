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

    final activeIndex = tabState.filteredTabs.indexWhere(
      (tab) => tab.id == activeTabId,
    );
    if (activeIndex == -1) return;

    final itemHeight = (MediaQuery.of(context).size.width - 32 - 8) / 2 / 0.75;
    final targetPosition = (activeIndex ~/ 2) * (itemHeight + 8);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        max(0.0, targetPosition - 50),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      builder: (context, tabState) {
        final filteredTabs = tabState.filteredTabs;
        final isIncognitoMode = tabState.isIncognitoMode;

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isIncognitoMode ? Colors.grey[900] : Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(tabState, filteredTabs.length),
              // Tabs grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: filteredTabs.isEmpty
                      ? _buildEmptyState(isIncognitoMode)
                      : GridView.builder(
                          controller: _scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: filteredTabs.length,
                          itemBuilder: (context, index) {
                            final tab = filteredTabs[index];
                            final isActive = tab.id == tabState.activeTab?.id;
                            final isSplitSecondary =
                                tab.id == tabState.splitSecondaryTabId;

                            return RepaintBoundary(
                              child: _TabCard(
                                key: ValueKey(tab.id),
                                tab: tab,
                                isActive: isActive,
                                isSplitSecondary: isSplitSecondary,
                                onTap: () => widget.onSelectTab(tab.id),
                                onSplit: isActive
                                    ? null
                                    : () {
                                        context.read<TabBloc>().add(
                                          tabState.isSplitViewEnabled
                                              ? SetSplitSecondaryTabEvent(
                                                  tab.id,
                                                )
                                              : EnableSplitViewEvent(tab.id),
                                        );
                                      },
                                onClose: () => widget.onCloseTab(tab.id),
                                canClose: filteredTabs.isNotEmpty,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(TabState tabState, int tabCount) {
    final isIncognitoMode = tabState.isIncognitoMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isIncognitoMode ? Colors.grey[850] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Row(
            children: [
              if (isIncognitoMode) ...[
                Image.asset(
                  'assets/logo/Incognito.png',
                  width: 18,
                  height: 18,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
              ],
              Text(
                isIncognitoMode ? 'Incognito Tabs' : 'Tabs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isIncognitoMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isIncognitoMode ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$tabCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isIncognitoMode
                        ? Colors.grey[300]
                        : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle incognito mode button
              Semantics(
                button: true,
                label: tabState.isSplitViewEnabled
                    ? 'Disable split view'
                    : 'Enable split view',
                child: GestureDetector(
                  onTap: () {
                    final bloc = context.read<TabBloc>();
                    if (tabState.isSplitViewEnabled) {
                      bloc.add(DisableSplitViewEvent());
                      return;
                    }

                    final activeTabId = tabState.activeTab?.id;
                    final secondary = tabState.filteredTabs.firstWhere(
                      (tab) => tab.id != activeTabId,
                      orElse: () => tabState.activeTab!,
                    );
                    if (secondary.id != activeTabId) {
                      bloc.add(EnableSplitViewEvent(secondary.id));
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: tabState.isSplitViewEnabled
                          ? Colors.blue
                          : (isIncognitoMode
                                ? Colors.grey[700]
                                : Colors.grey[300]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.vertical_split,
                      size: 18,
                      color: tabState.isSplitViewEnabled
                          ? Colors.white
                          : (isIncognitoMode
                                ? Colors.grey[300]
                                : Colors.grey[700]),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: isIncognitoMode
                    ? 'Switch to normal tabs'
                    : 'Switch to incognito tabs',
                child: GestureDetector(
                  onTap: () {
                    context.read<TabBloc>().add(ToggleIncognitoModeEvent());
                    // Scroll to active tab after mode change
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _scrollToActiveTab();
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isIncognitoMode
                          ? Colors.grey[700]
                          : Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                    child: isIncognitoMode
                        ? Icon(Icons.public, size: 18, color: Colors.grey[300])
                        : Image.asset(
                            'assets/logo/Incognito.png',
                            width: 18,
                            height: 18,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              // Add tab button
              Semantics(
                button: true,
                label: 'Add tab',
                child: GestureDetector(
                  onTap: () {
                    context.read<TabBloc>().add(AddTabEvent());
                    widget.onAddTab();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isIncognitoMode
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: isIncognitoMode
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isIncognitoMode) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIncognitoMode ? Icons.lock_outline : Icons.tab_outlined,
            size: 48,
            color: isIncognitoMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isIncognitoMode ? 'No incognito tabs' : 'No tabs open',
            style: TextStyle(
              fontSize: 14,
              color: isIncognitoMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          SizedBox(height: 8),
          Text(
            isIncognitoMode
                ? 'Tap + to create an incognito tab'
                : 'Tap + to open a new tab',
            style: TextStyle(
              fontSize: 12,
              color: isIncognitoMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

// Tab card widget
class _TabCard extends StatelessWidget {
  final dynamic tab;
  final bool isActive;
  final bool isSplitSecondary;
  final VoidCallback onTap;
  final VoidCallback? onSplit;
  final VoidCallback onClose;
  final bool canClose;

  const _TabCard({
    super.key,
    required this.tab,
    required this.isActive,
    required this.isSplitSecondary,
    required this.onTap,
    required this.onSplit,
    required this.onClose,
    required this.canClose,
  });

  @override
  Widget build(BuildContext context) {
    final isIncognito = tab.isIncognito ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isIncognito ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
          border: isActive || isSplitSecondary
              ? Border.all(
                  color: isSplitSecondary
                      ? Colors.orange
                      : (isIncognito ? Colors.grey[600]! : Colors.blue),
                  width: 2,
                )
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
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: isIncognito
                              ? Colors.grey[700]
                              : Colors.grey[100],
                          child: tab.thumbnail != null
                              ? Image.memory(
                                  tab.thumbnail!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  colorBlendMode: isIncognito
                                      ? BlendMode.modulate
                                      : null,
                                  color: isIncognito
                                      ? Colors.grey[400]?.withOpacity(0.3)
                                      : null,
                                )
                              : _buildEmptyThumbnail(isIncognito),
                        ),
                      ),
                      if (isActive)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isIncognito
                                  ? Colors.grey[600]
                                  : Colors.blue,
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
                      if (isSplitSecondary)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Split',
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
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isIncognito ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTabUrl(tab.url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: isIncognito
                                ? Colors.grey[400]
                                : Colors.grey[600],
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
                      color: isIncognito
                          ? Colors.grey[600]?.withOpacity(0.9)
                          : Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: isIncognito ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            if (onSplit != null)
              Positioned(
                right: 6,
                bottom: 54,
                child: Semantics(
                  button: true,
                  label: 'Use tab in split view',
                  child: GestureDetector(
                    onTap: onSplit,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isSplitSecondary
                            ? Colors.orange
                            : (isIncognito
                                  ? Colors.grey[600]?.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.9)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.vertical_split,
                        size: 15,
                        color: isSplitSecondary
                            ? Colors.white
                            : (isIncognito ? Colors.white : Colors.grey[700]),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyThumbnail(bool isIncognito) {
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
          colors: isIncognito
              ? [
                  Colors.grey[700]!.withOpacity(0.8),
                  Colors.grey[800]!.withOpacity(0.6),
                ]
              : [color.withOpacity(0.8), color.withOpacity(0.6)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.url.isEmpty ? Icons.add_circle_outline : Icons.web,
              size: 36,
              color: isIncognito
                  ? Colors.grey[400]
                  : Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 8),
            Text(
              tab.url.isEmpty ? 'New Tab' : firstLetter,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isIncognito ? Colors.grey[400] : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromUrl(String url) {
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

  String _formatTabUrl(String url) {
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

  String _formatDisplayUrl(String url) {
    if (url.startsWith('https://')) {
      return url.substring(8);
    } else if (url.startsWith('http://')) {
      return url.substring(7);
    }
    return url;
  }
}
