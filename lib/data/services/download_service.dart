import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:browser_app/core/services/foreground_download_service.dart';
import 'package:browser_app/core/logger/app_logger.dart';
import 'package:browser_app/core/resources/app_strings.dart';
import 'package:browser_app/data/services/download_file_validator.dart';

class DownloadTask {
  final String id;
  final String url;
  final String fileName;
  final String filePath;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final double progress;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    required this.filePath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  DownloadTask copyWith({
    String? id,
    String? url,
    String? fileName,
    String? filePath,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    double? progress,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    String? clearErrorMessage,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearErrorMessage != null
          ? null
          : completedAt ?? this.completedAt,
      errorMessage: clearErrorMessage != null
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'fileName': fileName,
      'filePath': filePath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.index,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      url: json['url'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      totalBytes: json['totalBytes'] as int? ?? 0,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      status: DownloadStatus.values[json['status'] as int? ?? 0],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadService {
  DownloadService._();

  static final DownloadService _instance = DownloadService._();

  factory DownloadService() => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(minutes: 5),
    ),
  );
  final Map<String, CancelToken> _cancelTokens = {};
  final List<DownloadTask> _downloads = [];
  static const String _storageKey = 'downloads_list';
  final ForegroundDownloadService _foregroundService =
      ForegroundDownloadService();

  List<DownloadTask> get downloads => List.unmodifiable(_downloads);

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  // Load downloads from storage
  Future<void> loadDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString(_storageKey);
      if (downloadsJson != null) {
        final List<dynamic> decoded = jsonDecode(downloadsJson);
        _downloads.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _downloads.add(DownloadTask.fromJson(item));
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Download', 'Failed to load downloads', error: e);
    }
  }

  // Reset all downloads (used when loading to reset stale downloading tasks)
  Future<void> resetDownloads(List<DownloadTask> newDownloads) async {
    _downloads.clear();
    _downloads.addAll(newDownloads);
    await _saveDownloads();
  }

  // Save downloads to storage
  Future<void> _saveDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = jsonEncode(
        _downloads.map((t) => t.toJson()).toList(),
      );
      await prefs.setString(_storageKey, downloadsJson);
    } catch (e) {
      AppLogger.warning('Download', 'Failed to save downloads', error: e);
    }
  }

  // Helper to update and save
  void _updateDownload(int index, DownloadTask task, {bool save = true}) {
    _downloads[index] = task;
    if (save) {
      _saveDownloads();
    }
  }

  // Helper to add and save
  void _addDownload(DownloadTask task) {
    _downloads.add(task);
    _saveDownloads();
  }

  // Helper to remove and save
  void _removeDownload(int index) {
    _downloads.removeAt(index);
    _saveDownloads();
  }

  String _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      String fileName = path.split('/').last;

      // If filename doesn't have extension, generate one
      if (fileName.isEmpty || !fileName.contains('.')) {
        fileName = 'download_$_generateId()${_extractFileExtension(url)}';
      }

      // Sanitize filename - remove invalid characters
      fileName = _sanitizeFileName(fileName);

      return fileName;
    } catch (_) {
      return 'download_$_generateId()';
    }
  }

  String _sanitizeFileName(String fileName) {
    // Remove characters that are invalid in filenames
    // Invalid: < > : " / \ | ? * &
    final invalidChars = RegExp(r'[<>:"/\\|?*&]');
    String sanitized = fileName.replaceAll(invalidChars, '_');

    // Also replace ~ with _ if it appears problematic
    sanitized = sanitized.replaceAll('~', '_');

    // Ensure filename isn't empty after sanitization
    if (sanitized.isEmpty || sanitized == '.') {
      sanitized = 'download_$_generateId()';
    }

    return sanitized;
  }

  String _extractFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      if (path.contains('.')) {
        return '.${path.split('.').last}';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<String> _getDownloadDirectory() async {
    // Downloads are kept in app-specific storage (no MANAGE_EXTERNAL_STORAGE /
    // WRITE_EXTERNAL_STORAGE permission required on any Android version, and no
    // public Downloads folder access needed on iOS). Requesting All Files Access
    // is against Google Play policy for a browser's core download feature.
    Directory directory;
    if (Platform.isAndroid) {
      directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final downloadsPath = '${directory.path}/downloads';
    final downloadsDir = Directory(downloadsPath);
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsPath;
  }

  Future<String> _getUniqueFilePath(String directory, String fileName) async {
    String filePath = '$directory/$fileName';
    int counter = 1;

    while (await File(filePath).exists()) {
      final extension = _extractFileExtension(fileName);
      final nameWithoutExt = fileName.replaceAll(extension, '');
      filePath = '$directory/${nameWithoutExt}_$counter$extension';
      counter++;
    }

    return filePath;
  }

  Future<DownloadTask> startDownload(
    String url, {
    String? customFileName,
    Function(int downloaded, int total)? onProgress,
    Function(DownloadTask)? onStatusChange,
  }) async {
    final id = _generateId();

    // Follow redirects to get the final URL
    String finalUrl = url;
    String? fileNameFromHeaders;
    int? expectedContentLength;

    try {
      final response = await _dio.head(
        url,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      // Check if redirected
      final realUri = response.realUri.toString();

      if (realUri != url && realUri.isNotEmpty) {
        finalUrl = realUri;
      }

      // Try to get filename from Content-Disposition header
      final contentDisposition = response.headers['content-disposition']?.first;

      if (contentDisposition != null) {
        final filenameRegex = RegExp(
          r'''filename[^;=\n]*=((['"]).*?\2|[^;\n]*)''',
        );
        final matches = filenameRegex.allMatches(contentDisposition);
        if (matches.isNotEmpty) {
          var match = matches.first.group(1);
          if (match != null) {
            // Remove quotes if present
            match = match.replaceAll(RegExp(r'''^['"]|['"]$'''), '');
            fileNameFromHeaders = match;
          }
        }
      }

      // Check content type
      final contentType = response.headers['content-type']?.first;
      expectedContentLength = int.tryParse(
        response.headers['content-length']?.first ?? '',
      );
      if (customFileName == null &&
          fileNameFromHeaders == null &&
          contentType != null) {
        final inferredExtension = _extensionForContentType(contentType);
        final urlName = _extractFileNameFromUrl(finalUrl);
        if (_extractFileExtension(urlName).isEmpty &&
            inferredExtension.isNotEmpty) {
          fileNameFromHeaders = 'download_$_generateId()$inferredExtension';
        }
      }
    } catch (e) {
      AppLogger.warning('Download', 'HEAD request failed', error: e);
      // Continue with original URL
    }

    // Determine filename and sanitize it
    String fileName =
        customFileName ??
        fileNameFromHeaders ??
        _extractFileNameFromUrl(finalUrl);
    fileName = _sanitizeFileName(fileName);

    final downloadDir = await _getDownloadDirectory();
    final filePath = await _getUniqueFilePath(downloadDir, fileName);

    final task = DownloadTask(
      id: id,
      url: url,
      fileName: fileName,
      filePath: filePath,
      createdAt: DateTime.now(),
    );

    _addDownload(task);
    onStatusChange?.call(task);

    if (DownloadFileValidator.isHlsUrl(finalUrl)) {
      final failedTask = task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: AppStrings.hlsOfflineUnsupported,
      );
      final taskIndex = _downloads.indexWhere((item) => item.id == id);
      _updateDownload(taskIndex, failedTask);
      onStatusChange?.call(failedTask);
      return failedTask;
    }

    await _foregroundService.initialize();
    await _foregroundService.startForegroundService();

    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    try {
      final partialPath = '$filePath.part';
      final partialFile = File(partialPath);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      await _dio.download(
        finalUrl,
        partialPath,
        cancelToken: cancelToken,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
          headers: {'Connection': 'keep-alive'},
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final index = _downloads.indexWhere((t) => t.id == id);
            if (index != -1) {
              final currentTask = _downloads[index];
              if (currentTask.status != DownloadStatus.downloading &&
                  currentTask.status != DownloadStatus.pending) {
                return;
              }
              final progress = received / total;
              final updatedTask = currentTask.copyWith(
                status: DownloadStatus.downloading,
                totalBytes: total,
                downloadedBytes: received,
                progress: progress,
              );
              // Don't save on every progress update - only update memory
              _downloads[index] = updatedTask;
              onProgress?.call(received, total);
              onStatusChange?.call(updatedTask);
            }
          } else {
            AppLogger.verbose(
              'Download',
              'Received $received bytes; total size is unknown',
            );
          }
        },
      );

      final index = _downloads.indexWhere((t) => t.id == id);
      if (index != -1) {
        final actualBytes = await partialFile.length();
        final knownTotal = _downloads[index].totalBytes > 0
            ? _downloads[index].totalBytes
            : expectedContentLength;
        DownloadFileValidator.verifyLength(
          actual: actualBytes,
          expected: knownTotal,
        );
        await partialFile.rename(filePath);
        final completedTask = _downloads[index].copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          totalBytes: actualBytes,
          downloadedBytes: actualBytes,
          completedAt: DateTime.now(),
        );
        _updateDownload(index, completedTask);
        onStatusChange?.call(completedTask);
      }
    } catch (e) {
      if (_isCancelError(e)) {
        AppLogger.info('Download', 'Download paused or cancelled');
      } else {
        final partialFile = File('$filePath.part');
        if (await partialFile.exists()) {
          await partialFile.delete();
        }
        final index = _downloads.indexWhere((t) => t.id == id);
        if (index != -1) {
          final failedTask = _downloads[index].copyWith(
            status: DownloadStatus.failed,
            errorMessage: e.toString(),
          );
          _updateDownload(index, failedTask);
          onStatusChange?.call(failedTask);
        }
      }
    } finally {
      _cancelTokens.remove(id);
      await _foregroundService.stopForegroundService();
    }

    return _downloads.firstWhere((t) => t.id == id);
  }

  String _extensionForContentType(String contentType) {
    final normalized = contentType.split(';').first.trim().toLowerCase();
    const extensions = <String, String>{
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/gif': '.gif',
      'image/webp': '.webp',
      'image/svg+xml': '.svg',
      'video/mp4': '.mp4',
      'video/webm': '.webm',
      'audio/mpeg': '.mp3',
      'audio/mp4': '.m4a',
      'application/pdf': '.pdf',
    };
    return extensions[normalized] ?? '';
  }

  bool _isCancelError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.cancel;
    }
    return error.toString().contains('cancelled') ||
        error.toString().contains('canceled');
  }

  void pauseDownload(String id) {
    final index = _downloads.indexWhere((t) => t.id == id);

    if (index != -1) {
      _cancelTokens[id]?.cancel();

      final pausedTask = _downloads[index].copyWith(
        status: DownloadStatus.paused,
      );
      _updateDownload(index, pausedTask);
    } else {
      AppLogger.warning('Download', 'Pause ignored: task $id was not found');
    }
  }

  Future<DownloadTask?> resumeDownload(
    String id, {
    Function(int downloaded, int total)? onProgress,
    Function(DownloadTask)? onStatusChange,
  }) async {
    final index = _downloads.indexWhere((t) => t.id == id);
    if (index == -1) return null;

    final task = _downloads[index];
    if (task.status != DownloadStatus.paused) return null;

    // Update to pending first
    final pendingTask = task.copyWith(status: DownloadStatus.pending);
    _updateDownload(index, pendingTask);
    onStatusChange?.call(pendingTask);
    await _foregroundService.initialize();
    await _foregroundService.startForegroundService();

    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    try {
      final partialPath = '${task.filePath}.part';
      final partialFile = File(partialPath);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      await _dio.download(
        task.url,
        partialPath,
        cancelToken: cancelToken,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
          headers: {'Connection': 'keep-alive'},
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final currentIndex = _downloads.indexWhere((t) => t.id == id);
            if (currentIndex != -1) {
              final currentTask = _downloads[currentIndex];
              // Skip update if task is no longer downloading/pending
              if (currentTask.status != DownloadStatus.downloading &&
                  currentTask.status != DownloadStatus.pending) {
                return;
              }
              final progress = received / total;
              final updatedTask = currentTask.copyWith(
                status: DownloadStatus.downloading,
                totalBytes: total,
                downloadedBytes: received,
                progress: progress,
              );
              // Don't save on every progress update
              _downloads[currentIndex] = updatedTask;
              onProgress?.call(received, total);
              onStatusChange?.call(updatedTask);
            }
          }
        },
      );

      // Completed
      final completedIndex = _downloads.indexWhere((t) => t.id == id);
      if (completedIndex != -1) {
        final actualBytes = await partialFile.length();
        final knownTotal = _downloads[completedIndex].totalBytes;
        DownloadFileValidator.verifyLength(
          actual: actualBytes,
          expected: knownTotal > 0 ? knownTotal : null,
        );
        final destination = File(task.filePath);
        if (await destination.exists()) {
          await destination.delete();
        }
        await partialFile.rename(task.filePath);
        final completedTask = _downloads[completedIndex].copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          totalBytes: actualBytes,
          downloadedBytes: actualBytes,
          completedAt: DateTime.now(),
        );
        _updateDownload(completedIndex, completedTask);
        onStatusChange?.call(completedTask);
      }
    } catch (e) {
      if (_isCancelError(e)) {
        AppLogger.info('Download', 'Resume cancelled by user');
      } else {
        final partialFile = File('${task.filePath}.part');
        if (await partialFile.exists()) {
          await partialFile.delete();
        }
        final failedIndex = _downloads.indexWhere((t) => t.id == id);
        if (failedIndex != -1) {
          final failedTask = _downloads[failedIndex].copyWith(
            status: DownloadStatus.failed,
            errorMessage: e.toString(),
          );
          _updateDownload(failedIndex, failedTask);
          onStatusChange?.call(failedTask);
        }
      }
    } finally {
      _cancelTokens.remove(id);
      await _foregroundService.stopForegroundService();
    }

    return _downloads.firstWhere((t) => t.id == id);
  }

  void cancelDownload(String id) {
    _cancelTokens[id]?.cancel();
    _cancelTokens.remove(id);

    final index = _downloads.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _downloads[index];

      try {
        if (task.status != DownloadStatus.completed) {
          final file = File(task.filePath);
          if (file.existsSync()) {
            file.deleteSync();
          }
          final partialFile = File('${task.filePath}.part');
          if (partialFile.existsSync()) {
            partialFile.deleteSync();
          }
        }
      } catch (_) {}

      _removeDownload(index);
    }
  }

  void removeDownload(String id) {
    final index = _downloads.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _downloads[index];
      try {
        final file = File(task.filePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
        final partialFile = File('${task.filePath}.part');
        if (partialFile.existsSync()) {
          partialFile.deleteSync();
        }
      } catch (_) {}
      _removeDownload(index);
    }
  }

  void clearCompleted() {
    _downloads.removeWhere((task) {
      if (task.status == DownloadStatus.completed) {
        try {
          final file = File(task.filePath);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (_) {}
        return true;
      }
      return false;
    });
    _saveDownloads();
  }

  void clearAll() {
    for (final task in _downloads) {
      try {
        final file = File(task.filePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
    _downloads.clear();
    _cancelTokens.clear();
    _saveDownloads();
  }

  List<DownloadTask> getActiveDownloads() {
    return _downloads
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.pending,
        )
        .toList();
  }

  List<DownloadTask> getCompletedDownloads() {
    return _downloads
        .where((t) => t.status == DownloadStatus.completed)
        .toList();
  }

  DownloadTask? getDownload(String id) {
    try {
      return _downloads.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> retryDownload(
    String id, {
    Function(int downloaded, int total)? onProgress,
    Function(DownloadTask)? onStatusChange,
  }) async {
    final index = _downloads.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final task = _downloads[index];
    if (task.status == DownloadStatus.failed ||
        task.status == DownloadStatus.cancelled) {
      await startDownload(
        task.url,
        customFileName: task.fileName,
        onProgress: onProgress,
        onStatusChange: onStatusChange,
      );
    }
  }
}
