import 'package:browser_app/data/services/storage_service.dart';
import 'package:browser_app/domain/entities/tab_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('checkpoint restores normal tabs and excludes incognito', () async {
    const normal = TabEntity(
      id: 'normal',
      url: 'https://example.com',
      title: 'Example',
      index: 0,
    );
    const incognito = TabEntity(
      id: 'private',
      url: 'https://private.example.com',
      title: 'Private',
      index: 1,
      isIncognito: true,
    );

    await StorageService.checkpointSession(const [
      normal,
      incognito,
    ], incognito.id);

    final restored = await StorageService.loadTabs();
    expect(restored, [normal]);
    expect(await StorageService.loadActiveTabId(), normal.id);
  });

  test('session marker distinguishes interrupted and clean exits', () async {
    expect(await StorageService.wasLastSessionInterrupted(), isFalse);
    await StorageService.markSessionStarted();
    expect(await StorageService.wasLastSessionInterrupted(), isTrue);
    await StorageService.markSessionCleanExit();
    expect(await StorageService.wasLastSessionInterrupted(), isFalse);
  });
}
