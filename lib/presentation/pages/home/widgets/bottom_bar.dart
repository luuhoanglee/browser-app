import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BottomBar extends StatelessWidget {
  final dynamic activeTab;
  final dynamic tabState;
  final InAppWebViewController? controller;
  final VoidCallback onShowTabs;
  final VoidCallback onAddressBarTap;
  final VoidCallback onShowHistory;
  final VoidCallback onShowDownload;
  final VoidCallback onShowMedia;

  final bool isSearching;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSearch;

  const BottomBar({
    super.key,
    required this.activeTab,
    required this.tabState,
    required this.controller,
    required this.onShowTabs,
    required this.onAddressBarTap,
    required this.onShowHistory,
    required this.onShowDownload,
    required this.onShowMedia,
    required this.isSearching,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearch,
  });

  String _formatDisplayUrl(String url) {
    if (url.startsWith('https://')) {
      return url.substring(8);
    } else if (url.startsWith('http://')) {
      return url.substring(7);
    }
    return url;
  }

  bool _isSecure(String url) {
    return url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
        child: SafeArea(
          bottom: false,
          top: false,
          child: Padding(
          padding: const EdgeInsets.only(bottom:20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Address bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildAddressBar(context),
            ),
            // Navigation buttons
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavBarItem(Icons.chevron_left, () {
                    controller?.goBack();
                  }),
                  _buildNavBarItem(Icons.chevron_right, () {
                    controller?.goForward();
                  }),
                  _buildNavBarItem(Icons.history, onShowHistory),
                  _buildNavBarItem(Icons.play_arrow, onShowMedia),
                  _buildNavBarItem(Icons.download, onShowDownload),

                  _buildNavBarItemWithBadge(
                    Icons.copy,
                    onShowTabs,
                    badgeCount: tabState.tabs.length,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      )
      )
    );
  }

  Widget _buildAddressBar(BuildContext context) {
    final displayUrl = _formatDisplayUrl(activeTab.url);
    final showUrl = displayUrl.isNotEmpty;

    if (isSearching) {
      return Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              Icons.search,
              size: 18,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search or enter website name',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: onSearch,
              ),
            ),
            if (searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  searchController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.cancel, size: 16, color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onAddressBarTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            if (showUrl)
              Icon(
                _isSecure(activeTab.url) ? Icons.lock : Icons.lock_open,
                size: 14,
                color: Colors.grey[600],
              )
            else
              Icon(Icons.search, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                showUrl ? displayUrl : 'Search or enter website name',
                style: TextStyle(
                  fontSize: 16,
                  color: showUrl ? Colors.black87 : Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (showUrl)
              GestureDetector(
                onTap: () => controller?.reload(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.refresh, size: 18, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, VoidCallback onTap, {bool isActive = true}) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        width: 50,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 22,
          color: isActive ? Colors.grey[700] : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildNavBarItemWithBadge(IconData icon, VoidCallback onTap, {bool isActive = true, required int badgeCount}) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        width: 50,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? Colors.grey[700] : Colors.grey[400],
            ),
            if (badgeCount >= 1)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 14,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
