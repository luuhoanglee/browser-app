import '../../../domain/entities/saved_page_entity.dart';

sealed class SavedPageEvent {
  const SavedPageEvent();
}

class SavedPagesLoadEvent extends SavedPageEvent {
  const SavedPagesLoadEvent();
}

class SavedPageAddEvent extends SavedPageEvent {
  final String title;
  final String url;
  final SavedPageCollection collection;
  final String folder;

  const SavedPageAddEvent({
    required this.title,
    required this.url,
    required this.collection,
    this.folder = '',
  });
}

class SavedPageRemoveEvent extends SavedPageEvent {
  final String id;
  const SavedPageRemoveEvent(this.id);
}

class SavedPageUpdateEvent extends SavedPageEvent {
  final SavedPageEntity item;
  const SavedPageUpdateEvent(this.item);
}

class SavedPageToggleReadEvent extends SavedPageEvent {
  final String id;
  const SavedPageToggleReadEvent(this.id);
}

class SavedPagesImportEvent extends SavedPageEvent {
  final List<SavedPageEntity> items;
  const SavedPagesImportEvent(this.items);
}

class SavedPagesFilterEvent extends SavedPageEvent {
  final String query;
  final SavedPageCollection collection;
  final String? folder;

  const SavedPagesFilterEvent({
    required this.query,
    required this.collection,
    this.folder,
  });
}
