import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/quick_access_bloc.dart';
import '../bloc/quick_access_event.dart';
import '../bloc/quick_access_state.dart';
import '../models/quick_access_site.dart';

class EditSitesSheet extends StatelessWidget {
  const EditSitesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 0),
                ),
                const Spacer(),
              ],
            ),
          ),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Edit Quick Access',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B5CE7),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Hold and drag to reorder',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          // List
          Expanded(
            child: BlocBuilder<QuickAccessBloc, QuickAccessState>(
              builder: (context, state) {
                if (state.sites.isEmpty) {
                  return Center(
                    child: Text('No sites yet',
                        style: TextStyle(color: Colors.grey[400])),
                  );
                }
                return ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.sites.length,
                  onReorder: (oldIndex, newIndex) {
                    context.read<QuickAccessBloc>().add(
                          QuickAccessReorderEvent(oldIndex, newIndex),
                        );
                  },
                  itemBuilder: (context, index) {
                    final site = state.sites[index];
                    return _SiteListItem(
                      key: ValueKey(site.id),
                      site: site,
                      onDelete: () => context
                          .read<QuickAccessBloc>()
                          .add(QuickAccessRemoveEvent(site.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteListItem extends StatelessWidget {
  final QuickAccessSite site;
  final VoidCallback onDelete;

  const _SiteListItem({
    super.key,
    required this.site,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: site.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            site.initial,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: site.color,
            ),
          ),
        ),
        title: Text(
          site.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Text(
          site.url,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Delete
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFFE53935)),
              ),
            ),
            const SizedBox(width: 8),
            // Drag handle
            Icon(Icons.drag_handle_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
