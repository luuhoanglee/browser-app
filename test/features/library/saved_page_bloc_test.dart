import 'package:browser_app/domain/entities/saved_page_entity.dart';
import 'package:browser_app/domain/repositories/saved_page_repository.dart';
import 'package:browser_app/features/library/bloc/saved_page_bloc.dart';
import 'package:browser_app/features/library/bloc/saved_page_event.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySavedPageRepository implements SavedPageRepository {
  List<SavedPageEntity> items;
  _MemorySavedPageRepository([this.items = const []]);

  @override
  Future<List<SavedPageEntity>> load() async => List.from(items);

  @override
  Future<void> save(List<SavedPageEntity> items) async {
    this.items = List.from(items);
  }
}

void main() {
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('loads persisted saved pages', () async {
    final now = DateTime(2026, 8, 10);
    final repository = _MemorySavedPageRepository([
      SavedPageEntity(
        id: 'one',
        title: 'Pardix',
        url: 'https://example.com',
        folder: 'Browsers',
        collection: SavedPageCollection.bookmarks,
        isRead: false,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    final bloc = SavedPageBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const SavedPagesLoadEvent());
    await settle();

    expect(bloc.state.isLoaded, isTrue);
    expect(bloc.state.items.single.title, 'Pardix');
  });

  test('deduplicates equivalent URLs within a collection', () async {
    final repository = _MemorySavedPageRepository();
    final bloc = SavedPageBloc(repository);
    addTearDown(bloc.close);

    bloc.add(
      const SavedPageAddEvent(
        title: 'First',
        url: 'https://EXAMPLE.com/',
        collection: SavedPageCollection.bookmarks,
      ),
    );
    await settle();
    bloc.add(
      const SavedPageAddEvent(
        title: 'Updated',
        url: 'https://example.com',
        collection: SavedPageCollection.bookmarks,
        folder: 'News',
      ),
    );
    await settle();

    expect(bloc.state.items, hasLength(1));
    expect(bloc.state.items.single.title, 'Updated');
    expect(bloc.state.items.single.folder, 'News');
  });

  test('allows the same URL in bookmark and reading list', () async {
    final bloc = SavedPageBloc(_MemorySavedPageRepository());
    addTearDown(bloc.close);

    for (final collection in SavedPageCollection.values) {
      bloc.add(
        SavedPageAddEvent(
          title: 'Article',
          url: 'https://example.com/article',
          collection: collection,
        ),
      );
      await settle();
    }

    expect(bloc.state.items, hasLength(2));
  });

  test('filters by collection, folder and query', () async {
    final bloc = SavedPageBloc(_MemorySavedPageRepository());
    addTearDown(bloc.close);
    bloc.add(
      const SavedPageAddEvent(
        title: 'Flutter guide',
        url: 'https://dart.dev/flutter',
        collection: SavedPageCollection.readingList,
        folder: 'Development',
      ),
    );
    await settle();
    bloc.add(
      const SavedPagesFilterEvent(
        query: 'flutter',
        collection: SavedPageCollection.readingList,
        folder: 'Development',
      ),
    );
    await settle();

    expect(bloc.state.visibleItems, hasLength(1));
    expect(bloc.state.folders, ['Development']);
  });

  test('import merges without duplicating an existing URL', () async {
    final now = DateTime(2026, 8, 10);
    final existing = SavedPageEntity(
      id: 'existing',
      title: 'Existing',
      url: 'https://example.com',
      folder: '',
      collection: SavedPageCollection.bookmarks,
      isRead: false,
      createdAt: now,
      updatedAt: now,
    );
    final bloc = SavedPageBloc(_MemorySavedPageRepository([existing]));
    addTearDown(bloc.close);
    bloc.add(const SavedPagesLoadEvent());
    await settle();
    bloc.add(
      SavedPagesImportEvent([
        existing.copyWith(id: 'duplicate', url: 'https://EXAMPLE.com/'),
        existing.copyWith(id: 'new', url: 'https://example.org'),
      ]),
    );
    await settle();

    expect(bloc.state.items, hasLength(2));
  });
}
