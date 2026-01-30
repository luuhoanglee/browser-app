import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_type_dart/file_type_dart.dart';
import '../bloc/download_bloc.dart';
import '../bloc/download_event.dart';
import '../bloc/download_state.dart';
import '../../../data/services/download_service.dart';

class DownloadSheet extends StatefulWidget {
  final double heightFactor;
  final VoidCallback onClose;
  final VoidCallback? onExpand;

  const DownloadSheet({
    super.key,
    required this.heightFactor,
    required this.onClose,
    this.onExpand,
  });

  @override
  State<DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<DownloadSheet> {
  String _selectedTab = 'All';

  Future<void> _openFile(BuildContext context, String filePath, String fileName) async {
    print('[DOWNLOAD_SHEET] Opening file: $fileName');
    print('[DOWNLOAD_SHEET] Path: $filePath');

    final file = File(filePath);
    if (!await file.exists()) {
      print('[DOWNLOAD_SHEET] File not found: $filePath');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File not found: $fileName'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final result = await OpenFilex.open(filePath);
    print('[DOWNLOAD_SHEET] Open result: ${result.type} - ${result.message}');

    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open file: ${result.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = widget.heightFactor > 0.7;

    return Container(
      height: MediaQuery.of(context).size.height * widget.heightFactor,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          _buildDragHandle(isExpanded),
          _buildHeader(),
          Expanded(
            child: BlocBuilder<DownloadBloc, DownloadState>(
              builder: (context, state) {
                if (state.downloads.isEmpty) {
                  return _buildEmptyState();
                }
                return Column(
                  children: [
                    _buildTabs(state),
                    Expanded(
                      child: _buildDownloadsList(state, isExpanded),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(bool isExpanded) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 300) {
          widget.onClose();
          if (widget.onExpand != null && details.primaryVelocity! < 0 && !isExpanded) {
            widget.onExpand!();
          }
        }
      },
      child: Container(
        height: 30,
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, state) {
        final activeCount = state.active.length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Downloads',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (state.completed.isNotEmpty)
                    _buildClearButton('Clear Completed', () {
                      _showClearCompletedDialog(context);
                    }),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onClose,
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
    );
  }


  Future<void> _showClearCompletedDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Completed'),
        content: const Text('Are you sure you want to remove all completed downloads?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<DownloadBloc>().add(DownloadClearCompletedEvent());
    }
  }

  Widget _buildClearButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your downloads will appear here',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(DownloadState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabChip('All', state.downloads.length, _selectedTab == 'All'),
          const SizedBox(width: 8),
          _buildTabChip('Active', state.active.length, _selectedTab == 'Active'),
          const SizedBox(width: 8),
          _buildTabChip('Completed', state.completed.length, _selectedTab == 'Completed'),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int count, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$label $count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadsList(DownloadState state, bool isExpanded) {
    List<DownloadTask> downloads;
    switch (_selectedTab) {
      case 'Active':
        downloads = state.active;
        break;
      case 'Completed':
        downloads = state.completed;
        break;
      default:
        downloads = state.downloads;
    }

    if (downloads.isEmpty) {
      return const SizedBox.shrink();
    }

    final groupedDownloads = _groupByDate(downloads);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: groupedDownloads.length,
      itemBuilder: (context, index) {
        final entry = groupedDownloads.entries.elementAt(index);
        final dateLabel = entry.key;
        final items = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ...items.map((task) => _DownloadItemTile(
                  task: task,
                  onPause: () {
                    context.read<DownloadBloc>().add(DownloadPauseEvent(task.id));
                  },
                  onResume: () {
                    context.read<DownloadBloc>().add(DownloadResumeEvent(task.id));
                  },
                  onCancel: () {
                    context.read<DownloadBloc>().add(DownloadCancelEvent(task.id));
                  },
                  onRemove: () {
                    context.read<DownloadBloc>().add(DownloadRemoveEvent(task.id));
                  },
                  onRetry: () {
                    context.read<DownloadBloc>().add(DownloadRetryEvent(task.id));
                  },
                  onOpen: () {
                    _openFile(context, task.filePath, task.fileName);
                  },
                )),
          ],
        );
      },
    );
  }

  Map<String, List<DownloadTask>> _groupByDate(List<DownloadTask> downloads) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = <String, List<DownloadTask>>{};

    // Sort by createdAt descending (newest first)
    final sortedDownloads = List<DownloadTask>.from(downloads)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final task in sortedDownloads) {
      final taskDate = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );

      String dateLabel;
      if (taskDate == today) {
        dateLabel = 'Today';
      } else if (taskDate == yesterday) {
        dateLabel = 'Yesterday';
      } else {
        dateLabel = _formatDate(task.createdAt);
      }

      grouped.putIfAbsent(dateLabel, () => []).add(task);
    }

    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else if (date.year == now.year) {
      return '${date.day}/${date.month}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ===== FILE ITEM TILE =====
class _DownloadItemTile extends StatefulWidget {
  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  const _DownloadItemTile({
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRemove,
    required this.onRetry,
    required this.onOpen,
  });

  @override
  State<_DownloadItemTile> createState() => _DownloadItemTileState();
}

class _DownloadItemTileState extends State<_DownloadItemTile> {
  String _fileType = 'file';
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    if (widget.task.status == DownloadStatus.completed) {
      _detectFileType();
    }
  }

  Future<void> _detectFileType() async {
    if (_isDetecting) return;
    
    setState(() => _isDetecting = true);
    
    try {
      final file = File(widget.task.filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final result = FileType.fromBuffer(bytes);

        String detectedType = 'file';
        if (FileType.isImage(result)) {
          detectedType = 'image';
        } else if (FileType.isVideo(result)) {
          detectedType = 'video';
        } else if (FileType.isAudio(result)) {
          detectedType = 'audio';
        } else if (FileType.isDocument(result)) {
          detectedType = 'document';
        } else if (FileType.isArchive(result)) {
          detectedType = 'archive';
        } else if (FileType.isFont(result)) {
          detectedType = 'font';
        }

        if (mounted) {
          setState(() => _fileType = detectedType);
        }
      }
    } catch (e) {
      print('Error detecting file type: $e');
      // Fallback to extension-based detection
      _fileType = _detectFromExtension(widget.task.fileName);
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  String _detectFromExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    const videoExts = ['mp4', 'mov', 'avi', 'mkv', 'wmv'];
    const audioExts = ['mp3', 'wav', 'flac', 'aac', 'm4a'];
    const docExts = ['pdf', 'doc', 'docx', 'txt', 'rtf'];
    const archiveExts = ['zip', 'rar', '7z', 'tar', 'gz'];

    if (imageExts.contains(ext)) return 'image';
    if (videoExts.contains(ext)) return 'video';
    if (audioExts.contains(ext)) return 'audio';
    if (docExts.contains(ext)) return 'document';
    if (archiveExts.contains(ext)) return 'archive';
    return 'file';
  }

  IconData _getFileIcon() {
    switch (_fileType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'document':
        return Icons.description;
      case 'archive':
        return Icons.folder_zip;
      case 'font':
        return Icons.font_download;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getStatusColor() {
    switch (widget.task.status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.cancelled:
        return Colors.grey;
      case DownloadStatus.pending:
        return Colors.blue.shade300;
    }
  }

  String _getStatusText() {
    switch (widget.task.status) {
      case DownloadStatus.downloading:
        return 'Downloading...';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.cancelled:
        return 'Cancelled';
      case DownloadStatus.pending:
        return 'Pending...';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    final isImage = _fileType == 'image' && widget.task.status == DownloadStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.task.status == DownloadStatus.completed ? widget.onOpen : null,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(widget.task.filePath),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_getFileIcon(), size: 24, color: Colors.grey[700]),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getFileIcon(), size: 24, color: Colors.grey[700]),
                    ),
              title: Text(
                widget.task.fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.task.totalBytes > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_formatBytes(widget.task.downloadedBytes)} / ${_formatBytes(widget.task.totalBytes)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              trailing: _buildTrailingActions(),
            ),
          ),
          if (widget.task.status == DownloadStatus.downloading ||
              widget.task.status == DownloadStatus.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  LinearProgressIndicator(
                    value: widget.task.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(widget.task.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          if (widget.task.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                widget.task.errorMessage!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrailingActions() {
    switch (widget.task.status) {
      case DownloadStatus.downloading:
      case DownloadStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.pause, size: 20),
              onPressed: widget.onPause,
              tooltip: 'Pause',
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onCancel,
              tooltip: 'Cancel',
            ),
          ],
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 20),
              onPressed: widget.onResume,
              tooltip: 'Resume',
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onCancel,
              tooltip: 'Cancel',
            ),
          ],
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: widget.onRemove,
          tooltip: 'Remove',
        );
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: widget.onRetry,
              tooltip: 'Retry',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: widget.onRemove,
              tooltip: 'Remove',
            ),
          ],
        );
    }
  }
}