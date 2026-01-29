import 'package:browser_app/core/enum/media_type.dart';
import 'package:browser_app/features/media/models/media_extract_result.dart';

/// Base class for media states
abstract class MediaState {}

/// Initial state
class MediaInitial extends MediaState {}

/// Loading state while extracting media
class MediaLoading extends MediaState {}

/// State when media has been successfully loaded
class MediaLoaded extends MediaState {
  final MediaExtractResult result;
  final MediaType? activeFilter;

  MediaLoaded({
    required this.result,
    this.activeFilter,
  });

  /// Get filtered URLs based on active filter
  List<String> get filteredUrls {
    if (activeFilter == null) {
      return result.allUrls;
    }
    return result.getUrlsByType(activeFilter!);
  }

  int get imageCount => result.images.length;
  int get videoCount => result.videos.length;
  int get audioCount => result.audios.length;

  bool get isEmpty => result.isEmpty;


  bool get isNotEmpty => result.isNotEmpty;

  MediaLoaded copyWith({
    MediaExtractResult? result,
    MediaType? activeFilter,
  }) {
    return MediaLoaded(
      result: result ?? this.result,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  @override
  List<Object?> get props => [result, activeFilter];
}

class MediaError extends MediaState {
  final String message;

  MediaError(this.message);

  @override
  List<Object?> get props => [message];
}
