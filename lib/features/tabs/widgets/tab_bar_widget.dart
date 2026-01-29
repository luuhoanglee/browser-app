import 'package:flutter/material.dart';
import '../../../../domain/entities/tab_entity.dart';

class TabBarWidget extends StatelessWidget {
  final List<TabEntity> tabs;
  final TabEntity? activeTab;
  final Function(String) onTabSelect;
  final Function(String) onTabClose;
  final Function() onNewTab;

  const TabBarWidget({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.onTabSelect,
    required this.onTabClose,
    required this.onNewTab,
  });

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: tabs.length + 1,
        itemBuilder: (context, index) {
          if (index == tabs.length) {
            return _buildNewTabButton();
          }
          final tab = tabs[index];
          final isActive = activeTab?.id == tab.id;
          return _buildTabItem(tab, isActive);
        },
      ),
    );
  }

  Widget _buildTabItem(TabEntity tab, bool isActive) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? const Border(bottom: BorderSide(color: Colors.blue, width: 2))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTabSelect(tab.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab.title.isNotEmpty ? tab.title : 'New Tab',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (tab.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (tabs.length > 1)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => onTabClose(tab.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildNewTabButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onNewTab,
          borderRadius: BorderRadius.circular(8),
          child: const SizedBox(
            width: 40,
            child: Icon(Icons.add, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
