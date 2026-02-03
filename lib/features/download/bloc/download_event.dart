import '../../../data/services/download_service.dart';

abstract class DownloadEvent {
  @override
  String toString() {
    return 'DownloadEvent';
  }
}

class DownloadStartEvent extends DownloadEvent {
  final String url;
  final String? customFileName;

  DownloadStartEvent(this.url, {this.customFileName});

  @override
  String toString() => 'DownloadStartEvent(url: $url, fileName: $customFileName)';
}

class DownloadPauseEvent extends DownloadEvent {
  final String id;

  DownloadPauseEvent(this.id);
}

class DownloadResumeEvent extends DownloadEvent {
  final String id;

  DownloadResumeEvent(this.id);
}

class DownloadCancelEvent extends DownloadEvent {
  final String id;

  DownloadCancelEvent(this.id);
}

class DownloadRemoveEvent extends DownloadEvent {
  final String id;

  DownloadRemoveEvent(this.id);
}

class DownloadRetryEvent extends DownloadEvent {
  final String id;

  DownloadRetryEvent(this.id);
}

class DownloadClearCompletedEvent extends DownloadEvent {}

class DownloadClearAllEvent extends DownloadEvent {}

class DownloadUpdateEvent extends DownloadEvent {
  final DownloadTask task;

  DownloadUpdateEvent(this.task);
}

class DownloadProgressEvent extends DownloadEvent {
  final String id;
  final int downloaded;
  final int total;

  DownloadProgressEvent(this.id, this.downloaded, this.total);
}

class DownloadBatchStartEvent extends DownloadEvent {
  final List<BatchDownloadItem> items;

  DownloadBatchStartEvent(this.items);

  @override
  String toString() => 'DownloadBatchStartEvent(count: ${items.length})';
}

class DownloadBatchPauseEvent extends DownloadEvent {
  DownloadBatchPauseEvent();
}

class DownloadBatchResumeEvent extends DownloadEvent {
  DownloadBatchResumeEvent();
}

class DownloadBatchCancelEvent extends DownloadEvent {
  DownloadBatchCancelEvent();
}

class DownloadBatchItemCompletedEvent extends DownloadEvent {
  DownloadBatchItemCompletedEvent();
}

class DownloadBatchItemFailedEvent extends DownloadEvent {
  DownloadBatchItemFailedEvent();
}

class DownloadBatchItemCancelledEvent extends DownloadEvent {
  DownloadBatchItemCancelledEvent();
}

class DownloadBatchProcessQueueEvent extends DownloadEvent {
  DownloadBatchProcessQueueEvent();
}

class BatchDownloadItem {
  final String url;
  final String? customFileName;

  BatchDownloadItem({
    required this.url,
    this.customFileName,
  });
}
