import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:browser_app/core/logger/logger.dart';
import 'package:browser_app/core/services/fcm/notification_remote_service.dart';
import 'package:browser_app/core/shared/cache/cache_key.dart';
import 'package:browser_app/core/shared/cache/cache_manager.dart';
import 'dart:html' as html;

class FirebaseService {
  static const String _channelId = 'satrepschannel';
  static const String _channelName = 'SATREPS';
  static const String _channelDescription = 'SATREPS Notification';
  static const Importance _channelImportance = Importance.max;
  static const Priority _channelPriority = Priority.max;
  static const String _iconName = '@drawable/icon_fmc';

  static FirebaseMessaging? _firebaseMessaging;
  static FirebaseMessaging get firebaseMessaging =>
      FirebaseService._firebaseMessaging ?? FirebaseMessaging.instance;

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    FirebaseService._firebaseMessaging = FirebaseMessaging.instance;
    // FirebaseMessaging.instance.requestPermission();

    // await FirebaseService.initializeLocalNotifications();
    FirebaseService.onOpenedApp();
    FirebaseService.onMessage();
  }

  static Future<void> createDeviceToken() async {
    try {
      CacheManager<String> cacheManager =
          CacheManager<String>(keyData: CacheKey.fcmToken);
      final String? fcmTokenCache = await cacheManager.get();
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmTokenCache != fcmToken) {
        await cacheManager.save(fcmToken);

        // save into server
        NotificationRemoteService notificationRemoteService =
            NotificationRemoteService();
      }
      Logger.show("FirebaseMessagingService token: $fcmToken");
    } catch (e, s) {
      Logger.error("Error getting device token: $e", s);
    }
  }

  static FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeLocalNotifications() async {
    const InitializationSettings initSettings = InitializationSettings(
        android: AndroidInitializationSettings(_iconName),
        iOS: DarwinInitializationSettings());

    /// on did receive notification response = for when app is opened via notification while in foreground on android
    await FirebaseService.localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onTapNotification,
    );

    /// register for android
    if (Platform.isAndroid) {
      await FirebaseService.localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
              _channelId, _channelName,
              description: _channelDescription,
              importance: _channelImportance));
    }

    /// need this for ios foreground notification
    await FirebaseService.firebaseMessaging
        .setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
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
          iOS: DarwinNotificationDetails());

  static void onMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      Logger.show(
          "FirebaseMessagingService onMessage data: ${message.data}, notification: ${message.notification}");
      if (kIsWeb) {
        html.Notification(
          message.notification?.title ?? '',
          body: message.notification?.body,
        );
        return;
      }
      // if this is available when Platform.isIOS, you'll receive the notification twice
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

  Future<String?> requestFcmToken(int userID) async {
    final token = await FirebaseMessaging.instance.getToken();
    Logger.show("FirebaseMessagingService token: $token");
    return token;
  }

  /// when app is in the foreground
  static Future<void> onTapNotification(NotificationResponse response) async {
    String? payload = response.payload;

    ///open when the notification is clicked in the foreground
    Logger.show(
        "FirebaseMessagingService select notification payload: $payload");
    if (payload != null && payload.isNotEmpty) {
      /// handle payload here
    }
  }

  static void onOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      Logger.show(
          "FirebaseMessagingService User click a Notification data: ${event.data}");
      if (event.data.isNotEmpty) {
        /// handle payload here
      }
    });
  }
}
