enum MediaType {
  image,
  video,
  audio,
}

extension MediaTypeExtension on MediaType {
  bool get isImage => this == MediaType.image;

  bool get isVideo => this == MediaType.video;

  bool get isAudio => this == MediaType.audio;

  String get displayName {
    switch (this) {
      case MediaType.image:
        return 'Image';
      case MediaType.video:
        return 'Video';
      case MediaType.audio:
        return 'Audio';
    }
  }
}
