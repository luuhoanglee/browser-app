import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/download_service.dart';
import '../../../data/services/download_notification_service.dart';
import 'download_event.dart';
import 'download_state.dart';

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  final DownloadService _downloadService = DownloadService();
  final DownloadNotificationService _notificationService =
      DownloadNotificationService();
  static const int _maxConcurrentDownloads = 5;
  final List<BatchDownloadItem> _batchQueue = [];
  final Set<String> _activeBatchDownloads = {};
  bool _isBatchProcessing = false;
  bool _hasEmittedBatchComplete = false;

  DownloadBloc() : super(const DownloadState()) {
    _notificationService.initialize();
    on<DownloadStartEvent>(_onStartDownload);
    on<DownloadPauseEvent>(_onPauseDownload);
    on<DownloadResumeEvent>(_onResumeDownload);
    on<DownloadCancelEvent>(_onCancelDownload);
    on<DownloadRemoveEvent>(_onRemoveDownload);
    on<DownloadRetryEvent>(_onRetryDownload);
    on<DownloadClearCompletedEvent>(_onClearCompleted);
    on<DownloadClearAllEvent>(_onClearAll);
    on<DownloadUpdateEvent>(_onUpdateDownload);
    on<DownloadProgressEvent>(_onDownloadProgress);
    on<DownloadBatchStartEvent>(_onBatchStartDownload);
    on<DownloadBatchPauseEvent>(_onBatchPause);
    on<DownloadBatchResumeEvent>(_onBatchResume);
    on<DownloadBatchCancelEvent>(_onBatchCancel);
    on<DownloadBatchItemCompletedEvent>(_onBatchItemCompleted);
    on<DownloadBatchItemFailedEvent>(_onBatchItemFailed);
    on<DownloadBatchItemCancelledEvent>(_onBatchItemCancelled);
    on<DownloadBatchProcessQueueEvent>(_onBatchProcessQueue);

    _loadInitialDownloads();
  }

  void _loadInitialDownloads() async {
    await _downloadService.loadDownloads();
    final existingDownloads = _downloadService.downloads;

    // Reset downloading/pending tasks to paused and save
    final resetDownloads = existingDownloads.map((task) {
      if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.pending) {
        return task.copyWith(status: DownloadStatus.paused);
      }
      return task;
    }).toList();

    // Update the service with reset downloads
    await _downloadService.resetDownloads(resetDownloads);

    emit(state.copyWith(downloads: resetDownloads));
  }

  Future<void> _onStartDownload(
    DownloadStartEvent event,
    Emitter<DownloadState> emit,
  ) async {
    unawaited(
      _downloadService.startDownload(
        event.url,
        customFileName: event.customFileName,
        onProgress: (downloaded, total) {
          // Get latest task ID
          final currentDownloads = _downloadService.downloads;
          if (currentDownloads.isNotEmpty) {
            add(DownloadProgressEvent(
              currentDownloads.last.id,
              downloaded,
              total,
            ));
          }
        },
        onStatusChange: (updatedTask) {
          add(DownloadUpdateEvent(updatedTask));
        },
      ),
    );
  }

  Future<void> _onPauseDownload(
    DownloadPauseEvent event,
    Emitter<DownloadState> emit,
  ) async {
    print('[BLOC] Pause requested for ID: ${event.id}');
    _downloadService.pauseDownload(event.id);
    print('[BLOC] Pause completed, current downloads in service: ${_downloadService.downloads.length}');
    // Emit updated state from service
    final updatedDownloads = List<DownloadTask>.from(_downloadService.downloads);
    print('[BLOC] Emitting state with ${updatedDownloads.length} downloads');
    emit(state.copyWith(downloads: updatedDownloads));
  }

  Future<void> _onResumeDownload(
    DownloadResumeEvent event,
    Emitter<DownloadState> emit,
  ) async {
    unawaited(
      _downloadService.resumeDownload(
        event.id,
        onProgress: (downloaded, total) {
          add(DownloadProgressEvent(event.id, downloaded, total));
        },
        onStatusChange: (task) {
          add(DownloadUpdateEvent(task));
        },
      ),
    );
  }

  Future<void> _onCancelDownload(
    DownloadCancelEvent event,
    Emitter<DownloadState> emit,
  ) async {
    _downloadService.cancelDownload(event.id);
    // Remove from state - service already removed it
    final updatedDownloads = List<DownloadTask>.from(_downloadService.downloads);
    emit(state.copyWith(downloads: updatedDownloads));
  }

  Future<void> _onRemoveDownload(
    DownloadRemoveEvent event,
    Emitter<DownloadState> emit,
  ) async {
    _downloadService.removeDownload(event.id);
    final updatedDownloads = List<DownloadTask>.from(state.downloads)
      ..removeWhere((d) => d.id == event.id);
    emit(state.copyWith(downloads: updatedDownloads));
  }

  Future<void> _onRetryDownload(
    DownloadRetryEvent event,
    Emitter<DownloadState> emit,
  ) async {
    // Remove old failed task first
    final updatedDownloads = List<DownloadTask>.from(state.downloads);
    updatedDownloads.removeWhere((d) => d.id == event.id);
    emit(state.copyWith(downloads: updatedDownloads));

    // Start new download
    unawaited(
      _downloadService.retryDownload(
        event.id,
        onProgress: (downloaded, total) {
          add(DownloadProgressEvent(event.id, downloaded, total));
        },
        onStatusChange: (task) {
          add(DownloadUpdateEvent(task));
        },
      ),
    );
  }

  Future<void> _onClearCompleted(
    DownloadClearCompletedEvent event,
    Emitter<DownloadState> emit,
  ) async {
    _downloadService.clearCompleted();
    final updatedDownloads = List<DownloadTask>.from(state.downloads)
      ..removeWhere((d) => d.status == DownloadStatus.completed);
    emit(state.copyWith(downloads: updatedDownloads));
  }

  Future<void> _onClearAll(
    DownloadClearAllEvent event,
    Emitter<DownloadState> emit,
  ) async {
    _downloadService.clearAll();
    emit(state.copyWith(downloads: [], activeDownloads: {}));
  }

  Future<void> _onUpdateDownload(
    DownloadUpdateEvent event,
    Emitter<DownloadState> emit,
  ) async {
    final updatedDownloads = List<DownloadTask>.from(state.downloads);
    final index = updatedDownloads.indexWhere((d) => d.id == event.task.id);

    if (index != -1) {
      updatedDownloads[index] = event.task;
    } else {
      updatedDownloads.add(event.task);
    }

    final updatedActive = Map<String, DownloadTask>.from(state.activeDownloads);
    if (event.task.status == DownloadStatus.downloading ||
        event.task.status == DownloadStatus.pending) {
      updatedActive[event.task.id] = event.task;
    } else {
      updatedActive.remove(event.task.id);
    }

    _handleNotificationForTask(event.task);

    emit(state.copyWith(
      downloads: updatedDownloads,
      activeDownloads: updatedActive,
    ));
  }

  void _handleNotificationForTask(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        _notificationService.onDownloadProgress(task);
        break;
      case DownloadStatus.completed:
        _notificationService.onDownloadCompleted(task);
        break;
      case DownloadStatus.failed:
        _notificationService.onDownloadFailed(task);
        break;
      case DownloadStatus.cancelled:
        _notificationService.onDownloadCancelled(task);
        break;
      case DownloadStatus.paused:
        _notificationService.onDownloadPaused(task);
        break;
      case DownloadStatus.pending:
        // Don't show notification for pending
        break;
    }
  }

  Future<void> _onDownloadProgress(
    DownloadProgressEvent event,
    Emitter<DownloadState> emit,
  ) async {
    final updatedDownloads = List<DownloadTask>.from(state.downloads);
    final index = updatedDownloads.indexWhere((d) => d.id == event.id);

    if (index != -1) {
      final progress = event.total > 0 ? event.downloaded / event.total : 0.0;
      updatedDownloads[index] = updatedDownloads[index].copyWith(
        downloadedBytes: event.downloaded,
        totalBytes: event.total,
        progress: progress,
      );

      final updatedActive = Map<String, DownloadTask>.from(state.activeDownloads);
      updatedActive[event.id] = updatedDownloads[index];

      emit(state.copyWith(
        downloads: updatedDownloads,
        activeDownloads: updatedActive,
      ));
    }
  }

  Future<void> _onBatchStartDownload(
    DownloadBatchStartEvent event,
    Emitter<DownloadState> emit,
  ) async {
    _batchQueue.clear();
    _batchQueue.addAll(event.items);
    _activeBatchDownloads.clear();
    _hasEmittedBatchComplete = false;

    emit(state.copyWith(
      isBatchDownloading: true,
      batchTotalCount: event.items.length,
      batchCompletedCount: 0,
      batchFailedCount: 0,
    ));

    _processBatchQueue(emit);
  }

  Future<void> _processBatchQueue(Emitter<DownloadState> emit) async {
    if (_isBatchProcessing) return;
    _isBatchProcessing = true;

    while (_batchQueue.isNotEmpty && _activeBatchDownloads.length < _maxConcurrentDownloads) {
      final item = _batchQueue.removeAt(0);

      final taskId = await _startBatchItem(item);
      if (taskId != null) {
        _activeBatchDownloads.add(taskId);
      }

      // Small delay between starting downloads
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isBatchProcessing = false;

    // Check if batch is complete - return result instead of emitting here
    if (_activeBatchDownloads.isEmpty && _batchQueue.isEmpty && !_hasEmittedBatchComplete) {
      _hasEmittedBatchComplete = true;

      final completed = state.batchCompletedCount;
      final failed = state.batchFailedCount;
      final total = state.batchTotalCount;

      // Show batch completion notification
      if (total > 0) {
        print('[BATCH] Complete: $completed/$total succeeded, $failed failed');
        _notificationService.onBatchDownloadComplete(
          total: total,
          completed: completed,
          failed: failed,
        );
      }

      // Don't emit here, let the caller handle it
      return;
    }
  }

  Future<void> _onBatchProcessQueue(
    DownloadBatchProcessQueueEvent event,
    Emitter<DownloadState> emit,
  ) async {
    // This event is no longer needed as we call _processBatchQueue directly
    // Kept for compatibility in case it's triggered elsewhere
  }

  Future<String?> _startBatchItem(
    BatchDownloadItem item,
  ) async {
    String? taskId;

    await _downloadService.startDownload(
      item.url,
      customFileName: item.customFileName,
      onProgress: (downloaded, total) {
        if (taskId != null) {
          add(DownloadProgressEvent(taskId!, downloaded, total));
        }
      },
      onStatusChange: (task) {
        taskId = task.id;
        add(DownloadUpdateEvent(task));

        // Update batch counters using add instead of emit
        if (task.status == DownloadStatus.completed) {
          add(DownloadBatchItemCompletedEvent());
        } else if (task.status == DownloadStatus.failed) {
          add(DownloadBatchItemFailedEvent());
        } else if (task.status == DownloadStatus.cancelled) {
          add(DownloadBatchItemCancelledEvent());
        }
      },
    );

    return taskId;
  }

  Future<void> _onBatchPause(
    DownloadBatchPauseEvent event,
    Emitter<DownloadState> emit,
  ) async {
    // Pause all active batch downloads
    for (final taskId in List.from(_activeBatchDownloads)) {
      _downloadService.pauseDownload(taskId);
    }

    emit(state.copyWith(isBatchDownloading: false));
  }

  Future<void> _onBatchResume(
    DownloadBatchResumeEvent event,
    Emitter<DownloadState> emit,
  ) async {
    emit(state.copyWith(isBatchDownloading: true));

    // Resume paused downloads and continue processing queue
    final pausedTasks = state.downloads
        .where((d) => d.status == DownloadStatus.paused)
        .take(_maxConcurrentDownloads)
        .toList();

    for (final task in pausedTasks) {
      if (_activeBatchDownloads.length >= _maxConcurrentDownloads) break;

      _activeBatchDownloads.add(task.id);
      unawaited(
        _downloadService.resumeDownload(
          task.id,
          onProgress: (downloaded, total) {
            add(DownloadProgressEvent(task.id, downloaded, total));
          },
          onStatusChange: (updatedTask) {
            add(DownloadUpdateEvent(updatedTask));

            if (updatedTask.status == DownloadStatus.completed) {
              final newCompleted = state.batchCompletedCount + 1;
              emit(state.copyWith(batchCompletedCount: newCompleted));
              _activeBatchDownloads.remove(task.id);
              _processBatchQueue(emit);
            } else if (updatedTask.status == DownloadStatus.failed) {
              final newFailed = state.batchFailedCount + 1;
              emit(state.copyWith(batchFailedCount: newFailed));
              _activeBatchDownloads.remove(task.id);
              _processBatchQueue(emit);
            }
          },
        ),
      );
    }

    _processBatchQueue(emit);
  }

  Future<void> _onBatchCancel(
    DownloadBatchCancelEvent event,
    Emitter<DownloadState> emit,
  ) async {
    // Cancel all active batch downloads
    for (final taskId in List.from(_activeBatchDownloads)) {
      _downloadService.cancelDownload(taskId);
    }

    // Clear queue
    _batchQueue.clear();
    _activeBatchDownloads.clear();
    _isBatchProcessing = false;
    _hasEmittedBatchComplete = false;

    emit(state.copyWith(
      isBatchDownloading: false,
      batchTotalCount: 0,
      batchCompletedCount: 0,
      batchFailedCount: 0,
    ));
  }

  Future<void> _onBatchItemCompleted(
    DownloadBatchItemCompletedEvent event,
    Emitter<DownloadState> emit,
  ) async {
    final newCompleted = state.batchCompletedCount + 1;
    emit(state.copyWith(batchCompletedCount: newCompleted));

    // Get the last completed task to remove from active
    final lastCompleted = state.downloads
        .where((d) => d.status == DownloadStatus.completed)
        .lastOrNull;
    if (lastCompleted != null) {
      _activeBatchDownloads.remove(lastCompleted.id);
    }

    // Process queue first
    await _processBatchQueue(emit);

    // Check if batch is complete after processing
    if (_activeBatchDownloads.isEmpty && _batchQueue.isEmpty && !_hasEmittedBatchComplete) {
      _hasEmittedBatchComplete = true;
      emit(state.copyWith(isBatchDownloading: false));
    }
  }

  Future<void> _onBatchItemFailed(
    DownloadBatchItemFailedEvent event,
    Emitter<DownloadState> emit,
  ) async {
    final newFailed = state.batchFailedCount + 1;
    emit(state.copyWith(batchFailedCount: newFailed));

    // Get the last failed task to remove from active
    final lastFailed = state.downloads
        .where((d) => d.status == DownloadStatus.failed)
        .lastOrNull;
    if (lastFailed != null) {
      _activeBatchDownloads.remove(lastFailed.id);
    }

    // Process queue first
    await _processBatchQueue(emit);

    // Check if batch is complete after processing
    if (_activeBatchDownloads.isEmpty && _batchQueue.isEmpty && !_hasEmittedBatchComplete) {
      _hasEmittedBatchComplete = true;
      emit(state.copyWith(isBatchDownloading: false));
    }
  }

  Future<void> _onBatchItemCancelled(
    DownloadBatchItemCancelledEvent event,
    Emitter<DownloadState> emit,
  ) async {
    // Get the last cancelled task to remove from active
    final lastCancelled = state.downloads
        .where((d) => d.status == DownloadStatus.cancelled)
        .lastOrNull;
    if (lastCancelled != null) {
      _activeBatchDownloads.remove(lastCancelled.id);
    }

    // Process queue first
    await _processBatchQueue(emit);

    // Check if batch is complete after processing
    if (_activeBatchDownloads.isEmpty && _batchQueue.isEmpty && !_hasEmittedBatchComplete) {
      _hasEmittedBatchComplete = true;
      emit(state.copyWith(isBatchDownloading: false));
    }
  }
}
