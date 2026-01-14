import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../presentation/pages/home/models/quick_access_item.dart';
import '../bloc/tab_bloc.dart';
import '../bloc/tab_state.dart';
import '../bloc/tab_event.dart';

class EmptyPage extends StatelessWidget {
  final dynamic activeTab;
  final List<QuickAccessItem> quickAccessItems;
  final Function(QuickAccessItem) onQuickAccessTap;

  const EmptyPage({
    super.key,
    required this.activeTab,
    required this.quickAccessItems,
    required this.onQuickAccessTap,
  });

  String _formatDisplayUrl(String url) {
    if (url.startsWith('https://')) {
      return url.substring(8);
    } else if (url.startsWith('http://')) {
      return url.substring(7);
    }
    return url;
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

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Quick Access Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: quickAccessItems.length,
                    itemBuilder: (context, index) {
                      final item = quickAccessItems[index];
                      return _buildQuickAccessItem(context, item);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Recent Tabs Section
              BlocBuilder<TabBloc, TabState>(
                builder: (context, tabState) {
                  final recentTabs = tabState.tabs.where((t) => t.id != activeTab.id && t.url.isNotEmpty).take(4).toList();

                  if (recentTabs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Tabs',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...recentTabs.map((tab) => _buildRecentTabItem(context, tab, tabState)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildQuickAccessItem(BuildContext context, QuickAccessItem item) {
  return GestureDetector(
    onTap: () => onQuickAccessTap(item),
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  size: 24,
                  color: item.color,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        );
      },
    ),
  );
}


  Widget _buildRecentTabItem(BuildContext context, dynamic tab, TabState tabState) {
    return GestureDetector(
      onTap: () {
        context.read<TabBloc>().add(SelectTabEvent(tab.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.web, size: 20, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tab.title.isNotEmpty ? tab.title : 'New Tab',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDisplayUrl(tab.url),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
