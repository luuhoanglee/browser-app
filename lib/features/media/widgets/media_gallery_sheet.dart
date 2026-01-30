import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_filex/open_filex.dart';
import '../bloc/media_bloc.dart';
import '../bloc/media_event.dart';
import '../bloc/media_state.dart';
import '../../../core/enum/media_type.dart';
import '../../download/bloc/download_bloc.dart';
import '../../download/bloc/download_event.dart';
import '../../download/bloc/download_state.dart';
import '../../../data/services/download_service.dart';
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
  final Set<String> _selectedUrls = {};
  bool _isSelectionMode = false;

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

  void _toggleSelectionMode() {
    setState(() {
      if (_isSelectionMode) {
        _isSelectionMode = false;
        _selectedUrls.clear();
      } else {
        _isSelectionMode = true;
      }
    });
  }

  void _toggleUrlSelection(String url) {
    setState(() {
      if (_selectedUrls.contains(url)) {
        _selectedUrls.remove(url);
        if (_selectedUrls.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        if (_selectedUrls.length < 5) {
          _selectedUrls.add(url);
        }
      }
    });
  }

  void _selectFirst5(List<String> urls, Set<String> completedUrls) {
    // Note: completedUrls parameter is kept for compatibility but no longer used
    // The _DownloadButton widget now handles the completed state internally
    setState(() {
      _selectedUrls.clear();
      _isSelectionMode = true;
      int selected = 0;
      for (final url in urls) {
        if (selected >= 5) break;
        _selectedUrls.add(url);
        selected++;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedUrls.clear();
      _isSelectionMode = false;
    });
  }

  void _downloadSelected(BuildContext context) {
    if (_selectedUrls.isEmpty) return;

    final items = _selectedUrls.map((url) {
      final fileName = url.split('/').last;
      return BatchDownloadItem(
        url: url,
        customFileName: fileName,
      );
    }).toList();

    context.read<DownloadBloc>().add(DownloadBatchStartEvent(items));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${items.length} file(s)...'),
        duration: const Duration(seconds: 2),
      ),
    );

    _clearSelection();
  }

  @override
  void dispose() {
    _mediaBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
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
      ),
    );
  }

  Widget _buildHeader() {
    return RepaintBoundary(
      child: BlocBuilder<MediaBloc, MediaState>(
        bloc: _mediaBloc,
        builder: (context, mediaState) {
          final activeFilter = mediaState is MediaLoaded ? mediaState.activeFilter : null;
          final urls = mediaState is MediaLoaded ? mediaState.filteredUrls : <String>[];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    if (_isSelectionMode) ...[
                      // Selection mode actions
                      Text(
                        '${_selectedUrls.length}/5',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedUrls.isNotEmpty)
                        GestureDetector(
                          onTap: () => _downloadSelected(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.download, size: 18, color: Colors.white),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _clearSelection,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 18, color: Colors.red[700]),
                        ),
                      ),
                    ] else ...[
                      // Normal mode actions
                      if (urls.isNotEmpty)
                        GestureDetector(
                          onTap: () => _selectFirst5(urls, {}),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.select_all, size: 18, color: Colors.blue[700]),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _toggleSelectionMode,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_box_outline_blank, size: 18, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
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
              ],
            ),
          );
        },
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
              final isSelected = _selectedUrls.contains(url);

              return _MediaItem(
                url: url,
                state: state,
                onTap: () => _openMedia(url, state),
                isSelectionMode: _isSelectionMode,
                isSelected: isSelected,
                onToggleSelect: () => _toggleUrlSelection(url),
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
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;

  const _MediaItem({
    required this.url,
    required this.state,
    required this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onToggleSelect,
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
      child: GestureDetector(
        onTap: isSelectionMode ? onToggleSelect : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: _buildLeading(url, isImage, mediaType),
            title: Text(
              fileName,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              host,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            trailing: SizedBox(
              width: isSelectionMode ? 40 : null,
              child: isSelectionMode
                  ? (isSelected
                      ? Icon(Icons.check_circle, color: Colors.blue, size: 24)
                      : Icon(Icons.circle_outlined, color: Colors.grey, size: 24))
                  : _DownloadButton(
                      url: url,
                      fileName: fileName,
                    ),
            ),
          ),
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
class _DownloadButton extends StatefulWidget {
  final String url;
  final String fileName;

  const _DownloadButton({
    required this.url,
    required this.fileName,
  });

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  String? _downloadTaskId;
  bool _isDownloading = false;
  bool _isCompleted = false;
  String? _filePath;
  double _progress = 0.0;
  StreamSubscription<DownloadState>? _subscription;

  @override
  void initState() {
    super.initState();
    // Check if this URL is already downloaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingDownload();
    });
  }

  void _checkExistingDownload() {
    final bloc = context.read<DownloadBloc>();
    final state = bloc.state;
    final existingTask = state.downloads.where((t) => t.url == widget.url).lastOrNull;

    if (existingTask != null) {
      if (existingTask.status == DownloadStatus.completed) {
        setState(() {
          _isCompleted = true;
          _filePath = existingTask.filePath;
          _progress = 1.0;
          _downloadTaskId = existingTask.id;
        });
      } else if (existingTask.status == DownloadStatus.downloading) {
        setState(() {
          _isDownloading = true;
          _progress = existingTask.progress;
          _downloadTaskId = existingTask.id;
        });
        _subscribeToUpdates(bloc);
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToUpdates(DownloadBloc bloc) {
    _subscription?.cancel();
    _subscription = bloc.stream.listen((state) {
      final ourTask = state.downloads.where((t) => t.url == widget.url).lastOrNull;

      if (ourTask != null) {
        if (_downloadTaskId == null) {
          setState(() {
            _downloadTaskId = ourTask.id;
          });
        }

        if (ourTask.status == DownloadStatus.downloading && mounted) {
          setState(() {
            _progress = ourTask.progress;
          });
        }

        if (ourTask.status == DownloadStatus.completed && mounted) {
          setState(() {
            _isDownloading = false;
            _isCompleted = true;
            _filePath = ourTask.filePath;
            _progress = 1.0;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded: ${widget.fileName}'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => _openFile(context),
              ),
            ),
          );

          _subscription?.cancel();
        } else if (ourTask.status == DownloadStatus.failed && mounted) {
          setState(() {
            _isDownloading = false;
            _isCompleted = false;
            _progress = 0.0;
          });

          print('[MEDIA] Download failed: ${ourTask.errorMessage}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: ${ourTask.errorMessage}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );

          _subscription?.cancel();
        }
      }
    });
  }

  void _startDownload(BuildContext context) {
    final url = widget.url;
    final fileName = widget.fileName;

    try {
      final bloc = context.read<DownloadBloc>();
      setState(() {
        _isDownloading = true;
        _isCompleted = false;
      });

      bloc.add(DownloadStartEvent(url, customFileName: fileName));

      _subscribeToUpdates(bloc);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting download...'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('[MEDIA] ERROR: DownloadBloc not found - $e');
      print('[MEDIA] Stack trace: ${StackTrace.current}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Download service not available - $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openFile(BuildContext context) async {
    if (_filePath == null) {
      print('❌ [VIEW] No file path available');
      return;
    }

    print('[VIEW] Attempting to open file: ${widget.fileName}');
    print('[VIEW] Path: $_filePath');

    final result = await OpenFilex.open(_filePath!);

    print('[VIEW] Open result type: ${result.type}');
    print('[VIEW] Open result message: ${result.message}');

    if (result.type != ResultType.done) {
      print('[VIEW] Failed to open file');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open file: ${result.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      print('[VIEW] File opened successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) {
      final progressText = _progress > 0 ? '${(_progress * 100).toInt()}%' : '';
      return SizedBox(
        width: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: _progress > 0 ? _progress : null,
              ),
            ),
            if (progressText.isNotEmpty)
              Text(
                progressText,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
      );
    }

    if (_isCompleted) {
      return IconButton(
        icon: const Icon(Icons.check_circle, size: 18, color: Colors.green),
        onPressed: () => _openFile(context),
        tooltip: 'Open',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }

    return IconButton(
      icon: const Icon(Icons.download, size: 18),
      onPressed: () => _startDownload(context),
      tooltip: 'Download',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
