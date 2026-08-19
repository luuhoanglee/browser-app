import 'package:browser_app/data/services/storage_service.dart';
import 'package:browser_app/domain/entities/saved_page_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saved pages survive a storage round trip', () async {
    final now = DateTime(2026, 8, 10);
    final source = SavedPageEntity(
      id: 'saved',
      title: 'Pardix',
      url: 'https://example.com',
      folder: 'Browsers',
      collection: SavedPageCollection.readingList,
      isRead: true,
      createdAt: now,
      updatedAt: now,
    );

    await StorageService.saveSavedPages([source]);
    final restored = await StorageService.loadSavedPages();

    expect(restored, hasLength(1));
    expect(restored.single.title, source.title);
    expect(restored.single.folder, source.folder);
    expect(restored.single.collection, SavedPageCollection.readingList);
    expect(restored.single.isRead, isTrue);
  });

  test('invalid stored JSON is ignored safely', () async {
    SharedPreferences.setMockInitialValues({'saved_pages': '{broken'});

    expect(await StorageService.loadSavedPages(), isEmpty);
  });
}
