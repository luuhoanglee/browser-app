import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/analytics_event.dart';
import '../../../core/logger/app_logger.dart';
import '../../../domain/entities/saved_page_entity.dart';
import '../../../domain/repositories/saved_page_repository.dart';
import 'saved_page_event.dart';
import 'saved_page_state.dart';

class SavedPageBloc extends Bloc<SavedPageEvent, SavedPageState> {
  final SavedPageRepository _repository;

  SavedPageBloc(this._repository) : super(const SavedPageState()) {
    on<SavedPagesLoadEvent>(_onLoad);
    on<SavedPageAddEvent>(_onAdd);
    on<SavedPageRemoveEvent>(_onRemove);
    on<SavedPageUpdateEvent>(_onUpdate);
    on<SavedPageToggleReadEvent>(_onToggleRead);
    on<SavedPagesImportEvent>(_onImport);
    on<SavedPagesFilterEvent>(_onFilter);
  }

  static String normalizeUrl(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return trimmed.toLowerCase();
    final normalizedPath = uri.path == '/' ? '' : uri.path;
    return uri
        .replace(
          scheme: uri.scheme.toLowerCase(),
          host: uri.host.toLowerCase(),
          path: normalizedPath,
          fragment: '',
        )
        .toString();
  }

  Future<void> _onLoad(
    SavedPagesLoadEvent event,
    Emitter<SavedPageState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          items: await _repository.load(),
          isLoaded: true,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'SavedPages',
        'Load failed',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(isLoaded: true, error: 'Could not load saved pages.'),
      );
    }
  }

  Future<void> _onAdd(
    SavedPageAddEvent event,
    Emitter<SavedPageState> emit,
  ) async {
    final url = event.url.trim();
    if (url.isEmpty) return;
    final normalized = normalizeUrl(url);
    final duplicateIndex = state.items.indexWhere(
      (item) =>
          item.collection == event.collection &&
          normalizeUrl(item.url) == normalized,
    );
    final now = DateTime.now();
    final updated = List<SavedPageEntity>.from(state.items);
    if (duplicateIndex >= 0) {
      final existing = updated[duplicateIndex];
      updated[duplicateIndex] = existing.copyWith(
        title: _safeTitle(event.title, url),
        folder: event.folder.trim(),
        updatedAt: now,
      );
    } else {
      updated.add(
        SavedPageEntity(
          id: '${now.microsecondsSinceEpoch}_${normalized.hashCode.abs()}',
          title: _safeTitle(event.title, url),
          url: url,
          folder: event.folder.trim(),
          collection: event.collection,
          isRead: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await _persist(updated, emit);
    AppLogger.event(
      event.collection == SavedPageCollection.bookmarks
          ? AnalyticsEvent.bookmarkSaved
          : AnalyticsEvent.readingListSaved,
    );
  }

  Future<void> _onRemove(
    SavedPageRemoveEvent event,
    Emitter<SavedPageState> emit,
  ) async {
    await _persist(
      state.items.where((item) => item.id != event.id).toList(),
      emit,
    );
  }

  Future<void> _onUpdate(
    SavedPageUpdateEvent event,
    Emitter<SavedPageState> emit,
  ) async {
    final updated = state.items
        .map(
          (item) => item.id == event.item.id
              ? event.item.copyWith(updatedAt: DateTime.now())
              : item,
        )
        .toList();
    await _persist(updated, emit);
  }

  Future<void> _onToggleRead(
    SavedPageToggleReadEvent event,
    Emitter<SavedPageState> emit,
  ) async {
    final updated = state.items
        .map(
          (item) => item.id == event.id
              ? item.copyWith(isRead: !item.isRead, updatedAt: DateTime.now())
              : item,
        )
        .toList();
    await _persist(updated, emit);
  }

  Future<void> _onImport(
    SavedPagesImportEvent event,
    Emitter<SavedPageState> emit,
  ) async {
    final merged = List<SavedPageEntity>.from(state.items);
    for (final imported in event.items) {
      final index = merged.indexWhere(
        (item) =>
            item.collection == imported.collection &&
            normalizeUrl(item.url) == normalizeUrl(imported.url),
      );
      if (index < 0) {
        merged.add(imported);
      }
    }
    await _persist(merged, emit);
  }

  void _onFilter(SavedPagesFilterEvent event, Emitter<SavedPageState> emit) {
    emit(
      state.copyWith(
        query: event.query,
        collection: event.collection,
        folder: event.folder,
        clearFolder: event.folder == null,
      ),
    );
  }

  Future<void> _persist(
    List<SavedPageEntity> items,
    Emitter<SavedPageState> emit,
  ) async {
    try {
      await _repository.save(items);
      emit(state.copyWith(items: items, clearError: true));
    } catch (error, stackTrace) {
      AppLogger.error(
        'SavedPages',
        'Save failed',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(error: 'Could not save changes.'));
    }
  }

  static String _safeTitle(String title, String url) {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? url;
  }
}
