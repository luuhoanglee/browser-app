import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/resources/app_strings.dart';
import '../../../domain/entities/saved_page_entity.dart';
import '../bloc/saved_page_bloc.dart';
import '../bloc/saved_page_event.dart';
import '../bloc/saved_page_state.dart';
import '../services/saved_page_file_service.dart';

class SavedPagesSheet extends StatefulWidget {
  final String currentTitle;
  final String currentUrl;
  final bool isIncognito;
  final ValueChanged<String> onOpen;

  const SavedPagesSheet({
    super.key,
    required this.currentTitle,
    required this.currentUrl,
    required this.isIncognito,
    required this.onOpen,
  });

  @override
  State<SavedPagesSheet> createState() => _SavedPagesSheetState();
}

class _SavedPagesSheetState extends State<SavedPagesSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_applyFilter);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_applyFilter)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  SavedPageCollection get _collection => _tabController.index == 0
      ? SavedPageCollection.bookmarks
      : SavedPageCollection.readingList;

  void _applyFilter() {
    if (_tabController.indexIsChanging) return;
    final state = context.read<SavedPageBloc>().state;
    final changedCollection = _lastTabIndex != _tabController.index;
    _lastTabIndex = _tabController.index;
    context.read<SavedPageBloc>().add(
      SavedPagesFilterEvent(
        query: _searchController.text,
        collection: _collection,
        folder: changedCollection ? null : state.folder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.black30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    AppStrings.savedPages,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: AppStrings.importOrExport,
                  onSelected: _handleFileAction,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'import',
                      child: Text(AppStrings.importBookmarks),
                    ),
                    PopupMenuItem(
                      value: 'export',
                      child: Text(AppStrings.exportBookmarks),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: AppStrings.cancelText,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.blackPrimary,
            tabs: const [
              Tab(text: AppStrings.bookmarks),
              Tab(text: AppStrings.readingList),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              decoration: const InputDecoration(
                hintText: AppStrings.searchSavedPages,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          _CurrentPageAction(
            title: widget.currentTitle,
            url: widget.currentUrl,
            isIncognito: widget.isIncognito,
            collection: _collection,
          ),
          BlocBuilder<SavedPageBloc, SavedPageState>(
            buildWhen: (previous, current) =>
                previous.folders != current.folders ||
                previous.folder != current.folder ||
                previous.collection != current.collection,
            builder: (context, state) {
              if (state.folders.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ChoiceChip(
                      label: const Text(AppStrings.allFolders),
                      selected: state.folder == null,
                      onSelected: (_) => _selectFolder(null),
                    ),
                    for (final folder in state.folders) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(folder),
                        selected: state.folder == folder,
                        onSelected: (_) => _selectFolder(folder),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<SavedPageBloc, SavedPageState>(
              builder: (context, state) {
                if (!state.isLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = state.visibleItems;
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.collections_bookmark_outlined, size: 48),
                        SizedBox(height: 12),
                        Text(AppStrings.noSavedPages),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _SavedPageTile(item: items[index], onOpen: widget.onOpen),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectFolder(String? folder) {
    context.read<SavedPageBloc>().add(
      SavedPagesFilterEvent(
        query: _searchController.text,
        collection: _collection,
        folder: folder,
      ),
    );
  }

  Future<void> _handleFileAction(String action) async {
    final bloc = context.read<SavedPageBloc>();
    try {
      if (action == 'import') {
        final imported = await SavedPageFileService.importHtml();
        if (imported == null || !mounted) return;
        bloc.add(SavedPagesImportEvent(imported));
        _showMessage('Imported ${imported.length} saved page(s).');
      } else {
        final exported = await SavedPageFileService.exportHtml(
          bloc.state.items,
        );
        if (mounted && exported) _showMessage('Saved pages exported.');
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'SavedPages',
        '$action failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) _showMessage('Could not $action saved pages.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CurrentPageAction extends StatelessWidget {
  final String title;
  final String url;
  final bool isIncognito;
  final SavedPageCollection collection;

  const _CurrentPageAction({
    required this.title,
    required this.url,
    required this.isIncognito,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return BlocBuilder<SavedPageBloc, SavedPageState>(
      builder: (context, state) {
        final exists = state.containsUrl(url, collection);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isIncognito || exists
                  ? null
                  : () => context.read<SavedPageBloc>().add(
                      SavedPageAddEvent(
                        title: title,
                        url: url,
                        collection: collection,
                      ),
                    ),
              icon: Icon(exists ? Icons.check : Icons.add),
              label: Text(
                isIncognito
                    ? AppStrings.incognitoSaveBlocked
                    : exists
                    ? AppStrings.alreadySaved
                    : collection == SavedPageCollection.bookmarks
                    ? AppStrings.saveBookmark
                    : AppStrings.addToReadingList,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedPageTile extends StatelessWidget {
  final SavedPageEntity item;
  final ValueChanged<String> onOpen;

  const _SavedPageTile({required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final host =
        Uri.tryParse(item.url)?.host.replaceFirst('www.', '') ?? item.url;
    return ListTile(
      leading: Icon(
        item.collection == SavedPageCollection.readingList
            ? (item.isRead ? Icons.check_circle : Icons.schedule)
            : Icons.bookmark,
        color: item.isRead ? AppColors.black30 : AppColors.greenPrimary,
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: item.isRead ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        item.folder.isEmpty ? host : '${item.folder} • $host',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => onOpen(item.url),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _handleAction(context, action),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text(AppStrings.editSavedPage),
          ),
          if (item.collection == SavedPageCollection.readingList)
            PopupMenuItem(
              value: 'read',
              child: Text(
                item.isRead ? AppStrings.markUnread : AppStrings.markRead,
              ),
            ),
          const PopupMenuItem(value: 'delete', child: Text(AppStrings.delete)),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    final bloc = context.read<SavedPageBloc>();
    if (action == 'delete') {
      bloc.add(SavedPageRemoveEvent(item.id));
    } else if (action == 'read') {
      bloc.add(SavedPageToggleReadEvent(item.id));
    } else {
      _showEditDialog(context, bloc);
    }
  }

  Future<void> _showEditDialog(BuildContext context, SavedPageBloc bloc) async {
    final titleController = TextEditingController(text: item.title);
    final folderController = TextEditingController(text: item.folder);
    final updated = await showDialog<SavedPageEntity>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.editSavedPage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: AppStrings.title),
            ),
            TextField(
              controller: folderController,
              decoration: const InputDecoration(labelText: AppStrings.folder),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              item.copyWith(
                title: titleController.text.trim(),
                folder: folderController.text.trim(),
              ),
            ),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    titleController.dispose();
    folderController.dispose();
    if (updated != null) bloc.add(SavedPageUpdateEvent(updated));
  }
}
