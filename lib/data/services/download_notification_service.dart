import 'package:browser_app/core/services/local_notification_service.dart';
import 'package:browser_app/data/services/download_service.dart';

class DownloadNotificationService {
  DownloadNotificationService._();

  static final DownloadNotificationService _instance =
      DownloadNotificationService._();

  factory DownloadNotificationService() => _instance;

  final LocalNotificationService _localNotification =
      LocalNotificationService();

  final Map<String, int> _lastNotifiedProgress = {};

  bool _showNotifications = true;

  Future<void> initialize() async {
    await _localNotification.initialize();
  }

  void setShowNotifications(bool show) {
    _showNotifications = show;
  }

  bool get showNotifications => _showNotifications;

  void onDownloadProgress(DownloadTask task) {
    if (!_showNotifications) return;

    if (task.status != DownloadStatus.downloading) return;

    final progress = (task.progress * 100).toInt();

    _localNotification.showDownloadProgressNotification(
      id: task.id,
      fileName: task.fileName,
      progress: progress,
      downloadedBytes: task.downloadedBytes,
      totalBytes: task.totalBytes,
    );
  }

  void onDownloadCompleted(DownloadTask task) {
    if (!_showNotifications) return;

    _localNotification.cancelNotification(task.id);

    _lastNotifiedProgress.remove(task.id);

    // Show completion notification
    _localNotification.showDownloadCompleteNotification(
      id: task.id,
      fileName: task.fileName,
      filePath: task.filePath,
    );
  }

  void onDownloadFailed(DownloadTask task) {
    if (!_showNotifications) return;

    _localNotification.cancelNotification(task.id);

    _lastNotifiedProgress.remove(task.id);

    _localNotification.showDownloadFailedNotification(
      id: task.id,
      fileName: task.fileName,
      errorMessage: task.errorMessage,
    );
  }

  void onDownloadCancelled(DownloadTask task) {
    _localNotification.cancelNotification(task.id);

    _lastNotifiedProgress.remove(task.id);
  }

  void onDownloadPaused(DownloadTask task) {
    _localNotification.cancelNotification(task.id);
  }

  void onBatchDownloadComplete({
    required int total,
    required int completed,
    required int failed,
  }) {
    if (!_showNotifications) return;

    _localNotification.cancelAllNotifications();

    _lastNotifiedProgress.clear();

    _localNotification.showBatchDownloadCompleteNotification(
      total: total,
      completed: completed,
      failed: failed,
    );
  }

}
