import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService _instance = LocalNotificationService._();

  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _downloadChannelId = 'download_notifications';
  static const String _downloadChannelName = 'Download Notifications';
  static const String _downloadChannelDescription =
      'Notifications for download progress and completion';

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    _initialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _downloadChannelId,
      _downloadChannelName,
      description: _downloadChannelDescription,
      importance: Importance.high,
      showBadge: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    // Handle iOS foreground notification
    debugPrint('iOS notification received: $title - $body');
  }

  Future<void> showDownloadProgressNotification({
    required String id,
    required String fileName,
    required int progress,
    required int downloadedBytes,
    required int totalBytes,
  }) async {
    if (!_initialized) await initialize();

    final String progressText = '$progress%';
    final String downloadedText = _formatBytes(downloadedBytes);
    final String totalText = _formatBytes(totalBytes);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      importance: Importance.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      indeterminate: false,
      autoCancel: false,
      ongoing: true,
      onlyAlertOnce: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      id.hashCode,
      'Downloading: $fileName',
      '$downloadedText of $totalText ($progressText)',
      platformChannelSpecifics,
      payload: id,
    );
  }

  Future<void> showDownloadCompleteNotification({
    required String id,
    required String fileName,
    required String filePath,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      importance: Importance.high,
      showProgress: false,
      autoCancel: true,
      ongoing: false,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      id.hashCode,
      'Download Complete',
      fileName,
      platformChannelSpecifics,
      payload: filePath,
    );
  }

  Future<void> showDownloadFailedNotification({
    required String id,
    required String fileName,
    String? errorMessage,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      importance: Importance.high,
      showProgress: false,
      autoCancel: true,
      ongoing: false,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      id.hashCode,
      'Download Failed',
      errorMessage != null ? '$fileName: $errorMessage' : fileName,
      platformChannelSpecifics,
      payload: id,
    );
  }

  Future<void> showBatchDownloadCompleteNotification({
    required int total,
    required int completed,
    required int failed,
  }) async {
    if (!_initialized) await initialize();

    String title;
    String body;

    if (failed == 0) {
      title = 'Batch Download Complete';
      body = 'Successfully downloaded $completed file(s)';
    } else if (completed == 0) {
      title = 'Batch Download Failed';
      body = 'Failed to download $failed file(s)';
    } else {
      title = 'Batch Download Partially Complete';
      body = '$completed succeeded, $failed failed';
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      importance: Importance.high,
      showProgress: false,
      autoCancel: true,
      ongoing: false,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
