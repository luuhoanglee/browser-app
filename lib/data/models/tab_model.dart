import 'dart:typed_data';
import '../../domain/entities/tab_entity.dart';

class TabModel extends TabEntity {
  const TabModel({
    required super.id,
    required super.url,
    required super.title,
    required super.index,
    super.isLoading = false,
    super.thumbnail,
    super.loadProgress = 0,
    super.lastAccessedAt,
  });

  factory TabModel.fromEntity(TabEntity entity) {
    return TabModel(
      id: entity.id,
      url: entity.url,
      title: entity.title,
      index: entity.index,
      isLoading: entity.isLoading,
      thumbnail: entity.thumbnail,
      loadProgress: entity.loadProgress,
      lastAccessedAt: entity.lastAccessedAt,
    );
  }

  TabEntity toEntity() {
    return this;
  }

  factory TabModel.create({required int index}) {
    return TabModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: '',
      title: 'New Tab',
      index: index,
      loadProgress: 0,
      lastAccessedAt: DateTime.now(),
    );
  }
}
