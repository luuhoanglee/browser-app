import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:browser_app/core/logger/analytics_event.dart';
import 'package:browser_app/core/logger/app_logger.dart';
import 'package:browser_app/core/services/fcm/notification_remote_service.dart';
import 'package:browser_app/core/shared/cache/cache_key.dart';
import 'package:browser_app/core/shared/cache/cache_manager.dart';

class FirebaseService {
  static const String _tag = 'FirebaseService';

  static const String _channelId = 'Dinofastschannel';
  static const String _channelName = 'DINOFAST';
  static const String _channelDescription = 'DINOFAST Notification';
  static const Importance _channelImportance = Importance.max;
  static const Priority _channelPriority = Priority.max;
  static const String _iconName = '@mipmap/ic_launcher';

  static FirebaseMessaging? _firebaseMessaging;
  static FirebaseMessaging get firebaseMessaging =>
      FirebaseService._firebaseMessaging ?? FirebaseMessaging.instance;

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();

    FirebaseService._firebaseMessaging = FirebaseMessaging.instance;
    FirebaseMessaging.instance.requestPermission();

    await _initializeCrashlytics();

    // Wire AppLogger to Firebase after initialization
    AppLogger.initFirebase();

    await FirebaseService.initializeLocalNotifications();
    FirebaseService.onOpenedApp();
    FirebaseService.onMessage();

    AppLogger.info(_tag, 'Firebase initialized successfully');
  }

  // ── Crashlytics ────────────────────────────────────────────────────────────

  static Future<void> _initializeCrashlytics() async {
    final crashlytics = FirebaseCrashlytics.instance;

    // Collect crashes in release mode; allow toggle in debug for testing
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Forward all uncaught Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.fatal(
        _tag,
        'Flutter framework error: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    // Forward errors outside of Flutter framework (Platform errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.fatal(
        _tag,
        'Platform dispatcher error',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    AppLogger.debug(_tag, 'Crashlytics initialized (collection: ${!kDebugMode})');
  }

  // ── FCM Token ──────────────────────────────────────────────────────────────

  static Future<void> createDeviceToken() async {
    try {
      final CacheManager<String> cacheManager =
          CacheManager<String>(keyData: CacheKey.fcmToken);
      final String? fcmTokenCache = await cacheManager.get();
      final String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null && fcmTokenCache != fcmToken) {
        await cacheManager.save(fcmToken);
        // Save to server
        NotificationRemoteService notificationRemoteService =
            NotificationRemoteService();
        AppLogger.info(_tag, 'FCM token refreshed');
      } else {
        AppLogger.debug(_tag, 'FCM token unchanged');
      }
    } catch (e, s) {
      AppLogger.error(_tag, 'Failed to retrieve FCM token', error: e, stackTrace: s);
    }
  }

  // ── Local Notifications ────────────────────────────────────────────────────

  static FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeLocalNotifications() async {
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings(_iconName),
      iOS: DarwinInitializationSettings(),
    );

    await FirebaseService.localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onTapNotification,
    );

    if (Platform.isAndroid) {
      await FirebaseService.localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: _channelImportance,
          ));
    }

    await FirebaseService.firebaseMessaging
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    AppLogger.debug(_tag, 'Local notifications initialized');
  }

  static NotificationDetails platformChannelSpecifics =
      const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      priority: _channelPriority,
      importance: _channelImportance,
    ),
    iOS: DarwinNotificationDetails(),
  );

  // ── Message Handlers ───────────────────────────────────────────────────────

  static void onMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      AppLogger.info(
        _tag,
        'FCM message received',
        params: {'title': message.notification?.title ?? ''},
      );

      AppLogger.event(AnalyticsEvent.notificationReceived, params: {
        'has_data': message.data.isNotEmpty,
      });

      if (Platform.isAndroid) {
        await FirebaseService.localNotificationsPlugin.show(
          0,
          message.notification!.title,
          message.notification!.body,
          FirebaseService.platformChannelSpecifics,
          payload: message.data.toString(),
        );
      }
    });
  }

  static Future<void> onTapNotification(NotificationResponse response) async {
    final String? payload = response.payload;
    AppLogger.info(_tag, 'Notification tapped', params: {
      'has_payload': (payload?.isNotEmpty ?? false),
    });

    AppLogger.event(AnalyticsEvent.notificationTapped);

    if (payload != null && payload.isNotEmpty) {
      // handle payload here
    }
  }

  static void onOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      AppLogger.info(_tag, 'App opened via notification', params: {
        'has_data': event.data.isNotEmpty,
      });

      AppLogger.event(AnalyticsEvent.notificationTapped, params: {
        'source': 'background',
      });

      if (event.data.isNotEmpty) {
        // handle payload here
      }
    });
  }

  // ── Analytics helpers ──────────────────────────────────────────────────────

  /// Set user properties visible in Analytics dashboard.
  static Future<void> setUserProperties({
    required String userId,
  }) async {
    if (kDebugMode) return;
    await FirebaseAnalytics.instance.setUserId(id: userId);
    AppLogger.debug(_tag, 'Analytics userId set');
  }

  Future<String?> requestFcmToken(int userID) async {
    final token = await FirebaseMessaging.instance.getToken();
    AppLogger.debug(_tag, 'FCM token requested for user $userID');
    return token;
  }
}
