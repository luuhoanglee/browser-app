import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';

class ForegroundDownloadService {
  ForegroundDownloadService._();

  static final ForegroundDownloadService _instance =
      ForegroundDownloadService._();

  factory ForegroundDownloadService() => _instance;

  bool _isInitialized = false;
  bool _isForegroundRunning = false;
  int _activeDownloadCount = 0;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    if (!Platform.isAndroid) {
      _isInitialized = true;
      return true;
    }

    try {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: 'Browser Download',
        notificationIcon: AndroidResource(
          name: 'ic_launcher',
          defType: 'mipmap', // or drawable
        ),
        enableWifiLock: true,
      );

      final success = await FlutterBackground.initialize(androidConfig: androidConfig);

      if (success) {
        _isInitialized = true;
        debugPrint('[FOREGROUND] Service initialized successfully');
      } else {
        debugPrint('[FOREGROUND] Failed to initialize');
      }

      return success;
    } catch (e) {
      debugPrint('[FOREGROUND] Initialization error: $e');
      return false;
    }
  }

  Future<bool> startForegroundService() async {
    if (!Platform.isAndroid) return true;
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('[FOREGROUND] Cannot start - not initialized');
        return false;
      }
    }

    _activeDownloadCount++;

    if (_isForegroundRunning) {
      return true;
    }

    try {
      final success = await FlutterBackground.enableBackgroundExecution();
      if (success) {
        _isForegroundRunning = true;
      } else {
        debugPrint('[FOREGROUND] Failed to enable background execution');
      }
      return success;
    } catch (e) {
      debugPrint('[FOREGROUND] Start error: $e');
      return false;
    }
  }

  Future<void> stopForegroundService() async {
    if (!Platform.isAndroid) return;
    if (!_isForegroundRunning) return;

    _activeDownloadCount--;

    // Only stop if no more active downloads
    if (_activeDownloadCount <= 0) {
      _activeDownloadCount = 0;

      try {
        await FlutterBackground.disableBackgroundExecution();
        _isForegroundRunning = false;
      } catch (e) {
        debugPrint('[FOREGROUND] Stop error: $e');
      }
    } else {
      debugPrint('[FOREGROUND] Still has active downloads, keeping service running');
    }
  }

  bool get isForegroundRunning => _isForegroundRunning;
  bool get isInitialized => _isInitialized;
  int get activeDownloadCount => _activeDownloadCount;

  void resetCount() {
    _activeDownloadCount = 0;
  }
}
