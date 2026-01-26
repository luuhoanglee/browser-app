import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../bloc/media_bloc.dart';
import '../bloc/media_event.dart';
import '../bloc/media_state.dart';
import '../../../core/enum/media_type.dart';
import 'image_viewer_page.dart';
import 'audio_player_page.dart';
import 'video_player_page.dart';

final _imageRegex = RegExp(r'\.(jpg|jpeg|png|gif|webp|svg)$', caseSensitive: false);
final _audioRegex = RegExp(r'\.(mp3|wav|ogg|aac|flac|m4a|wma)$', caseSensitive: false);
final _videoRegex = RegExp(r'\.(mp4|webm|mov|avi|mkv|m4v|flv|wmv|3gp|m3u8)$', caseSensitive: false);

class MediaGallerySheet extends StatefulWidget {
  final InAppWebViewController controller;
  final List<LoadedResource> loadedResources;

  const MediaGallerySheet({
    super.key,
    required this.controller,
    required this.loadedResources,
  });

  @override
  State<MediaGallerySheet> createState() => _MediaGallerySheetState();
}

class _MediaGallerySheetState extends State<MediaGallerySheet> {
  late MediaBloc _mediaBloc;

  @override
  void initState() {
    super.initState();
    _mediaBloc = MediaBloc();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mediaBloc.add(MediaExtractFromResources(widget.loadedResources));
    });
  }

  void _setFilter(MediaType? type) {
    _mediaBloc.add(MediaFilterChanged(type));
  }

  @override
  void dispose() {
    _mediaBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: [
          // Header with filter chips
          _buildHeader(),
          // Media list
          Expanded(
            child: BlocBuilder<MediaBloc, MediaState>(
              bloc: _mediaBloc,
              buildWhen: (previous, current) => previous != current,
              builder: (context, state) {
                if (state is MediaLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is MediaError) {
                  return _buildErrorState(state.message);
                } else if (state is MediaLoaded) {
                  if (state.activeFilter == null) {
                    return _buildEmptyState();
                  }

                  final urls = state.filteredUrls;

                  if (urls.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildMediaList(urls, state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: BlocBuilder<MediaBloc, MediaState>(
                bloc: _mediaBloc,
                builder: (context, state) {
                  final activeFilter = state is MediaLoaded ? state.activeFilter : null;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Images', MediaType.image, activeFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Videos', MediaType.video, activeFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Audio', MediaType.audio, activeFilter),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 20, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.perm_media_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No media found',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaList(List<String> urls, MediaLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Count label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            '${urls.length} ${_getTypeLabel(state.activeFilter)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: urls.length,
            cacheExtent: 500,
            itemBuilder: (context, index) {
              final url = urls[index];
              return _MediaItem(
                url: url,
                state: state,
                onTap: () => _openMedia(url, state),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openMedia(String url, MediaLoaded state) {
    final fileName = url.split('/').last;
    final mediaType = _getMediaTypeFromResult(url, state);

    if (mediaType == 'Image') {
      final imageUrls = state.result.images;
      final index = imageUrls.indexOf(url);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerPage(
            imageUrls: imageUrls,
            initialIndex: index >= 0 ? index : 0,
          ),
        ),
      );
    } else if (mediaType == 'Audio') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerPage(
            audioUrl: url,
          title: fileName,
        ),
      ),
    );
    } else if (mediaType == 'Video') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(
            videoUrl: url,
          title: fileName,
          ),
        ),
      );
    }
  }

  /// Get media type from result lists
  String _getMediaTypeFromResult(String url, MediaLoaded state) {
    if (state.result.images.contains(url)) return 'Image';
    if (state.result.videos.contains(url)) return 'Video';
    if (state.result.audios.contains(url)) return 'Audio';
    return 'Media';
  }

  Widget _buildFilterChip(String label, MediaType? type, MediaType? activeFilter) {
    final isSelected = activeFilter == type;
    return GestureDetector(
      onTap: () => _setFilter(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  bool _isAudio(String url) {
    final urlWithoutQuery = url.split('?')[0].toLowerCase();
    if (_audioRegex.hasMatch(urlWithoutQuery)) {
      return true;
    }
    // Special case for zingmp3
    return url.contains('zmdcdn.me') && url.contains('/audio/') || url.contains('/song/');
  }

  bool _isVideo(String url) {
    final urlWithoutQuery = url.split('?')[0].toLowerCase();
    return _videoRegex.hasMatch(urlWithoutQuery);
  }

  String _getTypeLabel(MediaType? type) {
    switch (type) {
      case MediaType.image:
        return 'Images';
      case MediaType.video:
        return 'Videos';
      case MediaType.audio:
        return 'Audio';
      case null:
        return 'Media';
    }
  }
}

/// Separate widget for media items to enable proper rebuilding
class _MediaItem extends StatelessWidget {
  final String url;
  final MediaLoaded state;
  final VoidCallback onTap;

  const _MediaItem({
    required this.url,
    required this.state,
    required this.onTap,
  });

  /// Get media type from result lists
  String _getMediaTypeFromResult() {
    if (state.result.images.contains(url)) return 'Image';
    if (state.result.videos.contains(url)) return 'Video';
    if (state.result.audios.contains(url)) return 'Audio';
    return 'Media';
  }

  /// Get icon based on media type
  IconData _getIconForMediaType(String mediaType) {
    switch (mediaType) {
      case 'Image':
        return Icons.image;
      case 'Video':
        return Icons.videocam;
      case 'Audio':
        return Icons.audio_file;
      default:
        return Icons.insert_link;
    }
  }

  /// Get label for media type
  String _getMediaTypeLabel(String mediaType) {
    return mediaType;
  }

  /// Extract host from URL
  String _extractHost(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = url.split('/').last;
    final lowerUrl = url.toLowerCase();
    final isImage = _imageRegex.hasMatch(lowerUrl);
    final isFromAudioList = state.result.audios.contains(url);
    final mediaType = _getMediaTypeFromResult();
    final host = _extractHost(url);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: ListTile(
          leading: _buildLeading(url, isImage, mediaType),
          title: Text(
            fileName,
            style: const TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            mediaType == 'Video' ? host : _getMediaTypeLabel(mediaType),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.download, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Download: $fileName')),
              );
            },
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildLeading(String url, bool isImage, String mediaType) {
    if (mediaType == 'Image') {
      final isSvg = url.toLowerCase().endsWith('.svg');

      if (isSvg) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: SvgPicture.network(
              url,
              fit: BoxFit.cover,
              placeholderBuilder: (context) => Container(
                width: 48,
                height: 48,
                color: Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey[200],
                  child: Icon(Icons.image, size: 24, color: Colors.grey[400]),
                );
              },
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 48,
              height: 48,
              color: Colors.grey[200],
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 48,
              height: 48,
              color: Colors.grey[200],
              child: Icon(Icons.image, size: 24, color: Colors.grey[400]),
            );
          },
        ),
      );
    }

    final iconData = _getIconForMediaType(mediaType);
    final isAudio = mediaType == 'Audio';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isAudio ? Colors.blue.shade50 : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: 24,
        color: isAudio ? Colors.blue : Colors.grey[600],
      ),
    );
  }
}
