import '../../../data/services/download_service.dart';

class DownloadState {
  final List<DownloadTask> downloads;
  final Map<String, DownloadTask> activeDownloads;
  final bool isBatchDownloading;
  final int batchTotalCount;
  final int batchCompletedCount;
  final int batchFailedCount;

  const DownloadState({
    this.downloads = const [],
    this.activeDownloads = const {},
    this.isBatchDownloading = false,
    this.batchTotalCount = 0,
    this.batchCompletedCount = 0,
    this.batchFailedCount = 0,
  });

  DownloadState copyWith({
    List<DownloadTask>? downloads,
    Map<String, DownloadTask>? activeDownloads,
    bool? isBatchDownloading,
    int? batchTotalCount,
    int? batchCompletedCount,
    int? batchFailedCount,
  }) {
    return DownloadState(
      downloads: downloads ?? this.downloads,
      activeDownloads: activeDownloads ?? this.activeDownloads,
      isBatchDownloading: isBatchDownloading ?? this.isBatchDownloading,
      batchTotalCount: batchTotalCount ?? this.batchTotalCount,
      batchCompletedCount: batchCompletedCount ?? this.batchCompletedCount,
      batchFailedCount: batchFailedCount ?? this.batchFailedCount,
    );
  }

  List<DownloadTask> get active =>
      downloads.where((d) => d.status == DownloadStatus.downloading).toList();

  List<DownloadTask> get completed =>
      downloads.where((d) => d.status == DownloadStatus.completed).toList();

  List<DownloadTask> get paused =>
      downloads.where((d) => d.status == DownloadStatus.paused).toList();

  List<DownloadTask> get failed =>
      downloads.where((d) => d.status == DownloadStatus.failed).toList();

  double get batchProgress =>
      batchTotalCount > 0 ? batchCompletedCount / batchTotalCount : 0.0;
}
