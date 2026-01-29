import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/enum/media_type.dart';

/// Base class for media events
abstract class MediaEvent {}

/// Event to extract media from already loaded resources
class MediaExtractFromResources extends MediaEvent {
  final List<LoadedResource> resources;

  MediaExtractFromResources(this.resources);
}

/// Event to refresh media extraction
class MediaRefreshRequested extends MediaEvent {}

/// Event to filter media by type
class MediaFilterChanged extends MediaEvent {
  final MediaType? filterType;

  MediaFilterChanged(this.filterType);
}

/// Event to clear all media
class MediaClearRequested extends MediaEvent {}
