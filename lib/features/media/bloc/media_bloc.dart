import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:browser_app/features/media/models/media_extract_result.dart';
import 'package:browser_app/core/utils/media_utils.dart';
import 'package:browser_app/core/enum/media_type.dart';
import 'media_event.dart';
import 'media_state.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  MediaBloc() : super(MediaInitial()) {
    on<MediaExtractFromResources>(_onExtractFromResources);
    on<MediaRefreshRequested>(_onRefreshRequested);
    on<MediaFilterChanged>(_onFilterChanged);
    on<MediaClearRequested>(_onClearRequested);
  }

  static MediaExtractResult _filterResources(List<LoadedResource> resources) {
    final images = <String>[];
    final videos = <String>[];
    final audios = <String>[];
    final skipped = <String>[];

    for (final resource in resources) {
      final url = resource.url?.toString();
      if (url == null || url.isEmpty) {
        skipped.add('EMPTY_OR_NULL');
        continue;
      }

      if (url.startsWith('data:') || url.startsWith('blob:')) {
        skipped.add('$url (data/blob)');
        continue;
      }

      final isImg = MediaUtils.isImage(url);
      final isVid = MediaUtils.isVideo(url);
      final isAud = MediaUtils.isAudio(url);

      if (isImg) {
        images.add(url);
      } else if (isVid) {
        videos.add(url);
      } else if (isAud) {
        audios.add(url);
      } else {
        skipped.add(url);
      }
    }

    return MediaExtractResult(
      images: images,
      videos: videos,
      audios: audios,
    );
  }

  void _onExtractFromResources(
    MediaExtractFromResources event,
    Emitter<MediaState> emit,
  ) {

    final result = _filterResources(event.resources);

    // Don't emit if no media found
    if (result.images.isEmpty && result.videos.isEmpty && result.audios.isEmpty) {
      emit(MediaLoaded(
        result: MediaExtractResult(),
        activeFilter: null,
      ));
      return;
    }

    // Default to first available type
    MediaType? defaultFilter;
    if (result.images.isNotEmpty) {
      defaultFilter = MediaType.image;
    } else if (result.videos.isNotEmpty) {
      defaultFilter = MediaType.video;
    } else if (result.audios.isNotEmpty) {
      defaultFilter = MediaType.audio;
    }

    emit(MediaLoaded(
      result: result,
      activeFilter: defaultFilter,
    ));
  }

  Future<void> _onRefreshRequested(
    MediaRefreshRequested event,
    Emitter<MediaState> emit,
  ) async {
    
    final currentState = state;
    if (currentState is MediaLoaded) {
      emit(MediaLoading());

      try {
        emit(currentState);
      } catch (e) {
        emit(MediaError('Failed to refresh: ${e.toString()}'));
      }
    }
  }

  void _onFilterChanged(
    MediaFilterChanged event,
    Emitter<MediaState> emit,
  ) {

    final currentState = state;

    if (currentState is MediaLoaded) {
      final newState = currentState.copyWith(activeFilter: event.filterType);
      emit(newState);
    }
  }

  void _onClearRequested(
    MediaClearRequested event,
    Emitter<MediaState> emit,
  ) {
    emit(MediaLoaded(
      result: const MediaExtractResult(),
      activeFilter: null,
    ));
  }
}
