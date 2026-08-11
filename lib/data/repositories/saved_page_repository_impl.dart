import '../../domain/entities/saved_page_entity.dart';
import '../../domain/repositories/saved_page_repository.dart';
import '../services/storage_service.dart';

class SavedPageRepositoryImpl implements SavedPageRepository {
  @override
  Future<List<SavedPageEntity>> load() => StorageService.loadSavedPages();

  @override
  Future<void> save(List<SavedPageEntity> items) =>
      StorageService.saveSavedPages(items);
}
