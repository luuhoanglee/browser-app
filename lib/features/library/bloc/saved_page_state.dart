import '../../../domain/entities/saved_page_entity.dart';

class SavedPageState {
  final List<SavedPageEntity> items;
  final bool isLoaded;
  final String query;
  final SavedPageCollection collection;
  final String? folder;
  final String? error;

  const SavedPageState({
    this.items = const [],
    this.isLoaded = false,
    this.query = '',
    this.collection = SavedPageCollection.bookmarks,
    this.folder,
    this.error,
  });

  List<SavedPageEntity> get visibleItems {
    final normalizedQuery = query.trim().toLowerCase();
    final result = items.where((item) {
      if (item.collection != collection) return false;
      if (folder != null && item.folder != folder) return false;
      if (normalizedQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(normalizedQuery) ||
          item.url.toLowerCase().contains(normalizedQuery);
    }).toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  List<String> get folders {
    final values = items
        .where(
          (item) => item.collection == collection && item.folder.isNotEmpty,
        )
        .map((item) => item.folder)
        .toSet()
        .toList();
    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  bool containsUrl(String url, SavedPageCollection target) {
    final normalized = _normalizeUrl(url);
    return items.any(
      (item) =>
          item.collection == target && _normalizeUrl(item.url) == normalized,
    );
  }

  static String _normalizeUrl(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return trimmed.toLowerCase();
    return uri
        .replace(
          scheme: uri.scheme.toLowerCase(),
          host: uri.host.toLowerCase(),
          path: uri.path == '/' ? '' : uri.path,
          fragment: '',
        )
        .toString();
  }

  SavedPageState copyWith({
    List<SavedPageEntity>? items,
    bool? isLoaded,
    String? query,
    SavedPageCollection? collection,
    String? folder,
    bool clearFolder = false,
    String? error,
    bool clearError = false,
  }) {
    return SavedPageState(
      items: items ?? this.items,
      isLoaded: isLoaded ?? this.isLoaded,
      query: query ?? this.query,
      collection: collection ?? this.collection,
      folder: clearFolder ? null : (folder ?? this.folder),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
