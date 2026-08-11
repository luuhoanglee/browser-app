import '../entities/saved_page_entity.dart';

abstract class SavedPageRepository {
  Future<List<SavedPageEntity>> load();
  Future<void> save(List<SavedPageEntity> items);
}
