import 'package:browser_app/widgets/logo_app.dart' show LogoApp;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/tab_bloc.dart';
import '../bloc/tab_state.dart';
import '../bloc/tab_event.dart';
import '../../quick_access/bloc/quick_access_bloc.dart';
import '../../quick_access/bloc/quick_access_state.dart';
import '../../quick_access/models/quick_access_site.dart';
import '../../quick_access/widgets/add_site_sheet.dart';
import '../../quick_access/widgets/edit_sites_sheet.dart';

class EmptyPage extends StatelessWidget {
  final dynamic activeTab;
  final VoidCallback? onSearchBarTap;
  final Function(String url) onQuickAccessTap;

  const EmptyPage({
    super.key,
    required this.activeTab,
    required this.onQuickAccessTap,
    this.onSearchBarTap,
  });

  String _formatDisplayUrl(String url) {
    if (url.startsWith('https://')) return url.substring(8);
    if (url.startsWith('http://')) return url.substring(7);
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final isIncognito = activeTab.isIncognito ?? false;

    return RepaintBoundary(
      child: Container(
        color: isIncognito ? const Color(0xFF1A1A2E) : Colors.white,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildHeader(isIncognito),
              const SizedBox(height: 12),
              _buildSearchBar(isIncognito),
              const SizedBox(height: 20),
              _buildQuickAccessSection(context, isIncognito),
              const SizedBox(height: 24),
              BlocBuilder<TabBloc, TabState>(
                builder: (context, tabState) =>
                    _buildRecentTabsSection(context, tabState, isIncognito),
              ),
              _buildPromoBanner(isIncognito),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isIncognito) {
    return Row(
      children: [
        LogoApp(isIncognito: isIncognito),
        const Spacer(),
        _HeaderIconButton(
          icon: isIncognito
              ? Icons.visibility_off_outlined
              : Icons.verified_user_outlined,
          color: isIncognito ? Colors.white54 : Colors.grey[600]!,
          onTap: () {},
        ),
        const SizedBox(width: 4),
        _HeaderIconButton(
          icon: Icons.more_vert,
          color: isIncognito ? Colors.white54 : Colors.grey[600]!,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isIncognito) {
    return GestureDetector(
      onTap: onSearchBarTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isIncognito
              ? const Color(0xFF2A2A3E)
              : const Color(0xFFF0F1F5),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                size: 20,
                color: isIncognito ? Colors.white38 : Colors.grey[500]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search or type web address',
                style: TextStyle(
                  color: isIncognito ? Colors.white38 : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.qr_code_scanner_outlined,
                size: 20,
                color: isIncognito ? Colors.white38 : Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context, bool isIncognito) {
    return BlocBuilder<QuickAccessBloc, QuickAccessState>(
      builder: (context, qaState) {
        final sites = qaState.sites;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Access',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isIncognito ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditSheet(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit_outlined,
                          size: 14, color: Color(0xFF6B5CE7)),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Color(0xFF6B5CE7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 14,
                crossAxisSpacing: 6,
                childAspectRatio: 0.72,
              ),
              itemCount: sites.length + 1,
              itemBuilder: (context, index) {
                if (index == sites.length) {
                  return _buildAddButton(context, isIncognito);
                }
                return _buildQuickAccessItem(
                    context, sites[index], isIncognito);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAccessItem(
      BuildContext context, QuickAccessSite site, bool isIncognito) {
    return GestureDetector(
      onTap: () => onQuickAccessTap(site.url),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isIncognito
                  ? const Color(0xFF2A2A3E)
                  : site.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              site.initial,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isIncognito ? Colors.white60 : site.color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            site.title,
            style: TextStyle(
              fontSize: 10,
              color: isIncognito ? Colors.white60 : const Color(0xFF444444),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, bool isIncognito) {
    return GestureDetector(
      onTap: () => _showAddSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isIncognito ? Colors.white24 : Colors.grey[350]!,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.add,
              size: 22,
              color: isIncognito ? Colors.white38 : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add',
            style: TextStyle(
              fontSize: 10,
              color: isIncognito ? Colors.white38 : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<QuickAccessBloc>(),
        child: const AddSiteSheet(),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<QuickAccessBloc>(),
        child: const EditSitesSheet(),
      ),
    );
  }

  Widget _buildRecentTabsSection(
      BuildContext context, TabState tabState, bool isIncognito) {
    final recentTabs = tabState.filteredTabs
        .where((t) => t.id != activeTab.id && t.url.isNotEmpty)
        .toList()
      ..sort((a, b) {
        final aTime =
            a.lastAccessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.lastAccessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    final topTabs = recentTabs.take(4).toList();

    if (topTabs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Tabs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isIncognito ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'View all >',
                style: TextStyle(
                  color: Color(0xFF2196F3),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...topTabs.map((tab) => _buildRecentTabItem(context, tab, isIncognito)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecentTabItem(
      BuildContext context, dynamic tab, bool isIncognito) {
    final displayUrl = _formatDisplayUrl(tab.url);
    final domain = Uri.tryParse(tab.url)?.host ?? '';
    final initial = domain.isNotEmpty ? domain[0].toUpperCase() : 'W';
    final avatarColor = _colorFromString(domain);

    return GestureDetector(
      onTap: () => context.read<TabBloc>().add(SelectTabEvent(tab.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isIncognito
              ? const Color(0xFF2A2A3E)
              : const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: avatarColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tab.title.isNotEmpty ? tab.title : 'New Tab',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isIncognito
                          ? Colors.white70
                          : const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayUrl,
                    style: TextStyle(
                      fontSize: 11,
                      color: isIncognito ? Colors.white38 : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.more_vert,
              size: 18,
              color: isIncognito ? Colors.white38 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(bool isIncognito) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B5CE7), Color(0xFF9C6FE8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.shield_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'PARDIX',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Browse Fast.\nStay Private.\nAd-Free.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Block ads, protect your privacy\nand enjoy a cleaner web.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(Icons.lock_rounded, size: 36, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorFromString(String str) {
    if (str.isEmpty) return Colors.blue;
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final hash = str.codeUnits.fold(0, (prev, c) => prev + c);
    return colors[hash % colors.length];
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}
