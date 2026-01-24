import 'package:browser_app/core/enum/media_type.dart';

/// Result class for resource extraction from WebResourceResponse
class MediaResourceType {
  /// The URL of the resource
  final String url;

  /// The detected media type
  final MediaType type;

  const MediaResourceType(this.url, this.type);

  /// Constant representing no media resource
  static const MediaResourceType none = MediaResourceType('', MediaType.image);

  /// Check if this is an image resource
  bool get isImage => type == MediaType.image;

  /// Check if this is a video resource
  bool get isVideo => type == MediaType.video;

  /// Check if this is an audio resource
  bool get isAudio => type == MediaType.audio;

  @override
  String toString() {
    return 'MediaResourceType(url: $url, type: $type)';
  }
}
