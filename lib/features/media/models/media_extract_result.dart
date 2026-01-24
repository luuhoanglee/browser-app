import 'package:browser_app/core/enum/media_type.dart';

/// Result class containing extracted media URLs from a web page
class MediaExtractResult {
  /// List of image URLs found
  final List<String> images;

  /// List of video URLs found
  final List<String> videos;

  /// List of audio URLs found
  final List<String> audios;

  const MediaExtractResult({
    this.images = const [],
    this.videos = const [],
    this.audios = const [],
  });

  /// Total number of media items found
  int get totalItems => images.length + videos.length + audios.length;

  /// Get all media URLs as a single list
  List<String> get allUrls => [...images, ...videos, ...audios];

  /// Check if no media was found
  bool get isEmpty => images.isEmpty && videos.isEmpty && audios.isEmpty;

  /// Check if any media was found
  bool get isNotEmpty => !isEmpty;

  /// Get URLs by media type
  List<String> getUrlsByType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return images;
      case MediaType.video:
        return videos;
      case MediaType.audio:
        return audios;
    }
  }

  /// Create a copy with modified fields
  MediaExtractResult copyWith({
    List<String>? images,
    List<String>? videos,
    List<String>? audios,
  }) {
    return MediaExtractResult(
      images: images ?? this.images,
      videos: videos ?? this.videos,
      audios: audios ?? this.audios,
    );
  }

  @override
  String toString() {
    return 'MediaExtractResult(images: ${images.length}, videos: ${videos.length}, audios: ${audios.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MediaExtractResult &&
        other.images.length == images.length &&
        other.videos.length == videos.length &&
        other.audios.length == audios.length;
  }

  @override
  int get hashCode => images.length ^ videos.length ^ audios.length;
}
