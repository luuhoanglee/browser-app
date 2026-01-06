import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class TabEntity extends Equatable {
  final String id;
  final String url;
  final String title;
  final int index;
  final bool isLoading;
  final Uint8List? thumbnail;
  final int loadProgress;

  const TabEntity({
    required this.id,
    required this.url,
    required this.title,
    required this.index,
    this.isLoading = false,
    this.thumbnail,
    this.loadProgress = 0,
  });

  TabEntity copyWith({
    String? id,
    String? url,
    String? title,
    int? index,
    bool? isLoading,
    Uint8List? thumbnail,
    int? loadProgress,
  }) {
    return TabEntity(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      index: index ?? this.index,
      isLoading: isLoading ?? this.isLoading,
      thumbnail: thumbnail ?? this.thumbnail,
      loadProgress: loadProgress ?? this.loadProgress,
    );
  }

  @override
  List<Object?> get props => [id, url, title, index, isLoading, thumbnail, loadProgress];
}
