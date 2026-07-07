import 'dart:async' show runZonedGuarded;
import 'dart:io';
import 'package:browser_app/core/resources/app_colors.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart' show FirebaseCrashlytics;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:browser_app/core/logger/app_logger.dart';
import 'package:browser_app/core/services/local_notification_service.dart';
import 'package:browser_app/data/services/download_notification_service.dart';
import 'presentation/pages/home/home_page.dart';
import 'package:browser_app/core/services/fcm/firebase_service.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await FirebaseService.initializeFirebase();

    _initBackgroundServices();

    runApp(const BrowserApp());
  }, (error, stack) {
    AppLogger.fatal('App', 'Unhandled zone error', error: error, stackTrace: stack);
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

void _initBackgroundServices() {
  Future.microtask(() async {
    try {
      await LocalNotificationService().initialize();
      await DownloadNotificationService().initialize();
      await FirebaseService.createDeviceToken();
    } catch (e, s) {
      AppLogger.error('App', 'Background init failed', error: e, stackTrace: s);
    }
  });
}


final GlobalKey<HomeViewWrapperState> homeViewKey =
    GlobalKey<HomeViewWrapperState>();

class BrowserApp extends StatefulWidget {
  const BrowserApp({super.key});

  @override
  State<BrowserApp> createState() => _BrowserAppState();
}

class _BrowserAppState extends State<BrowserApp> {
  static const _channel =
      MethodChannel('com.dino.pardix/deeplink');

  String? _initialLink;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinkListener();
      _getInitialLink();
    });
  }

  Future<void> _getInitialLink() async {
    try {
      final String? link = await _channel.invokeMethod('getInitialLink');
      if (link != null && mounted) {
        setState(() => _initialLink = link);
      }
    } catch (e, s) {
      AppLogger.warning('App', 'Failed to get initial deep link', error: e, stackTrace: s);
    }
  }

  void _initDeepLinkListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final String url = call.arguments as String;
        homeViewKey.currentState?.loadDeepLinkUrl(url);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Browser App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: HomePage(
        key: homeViewKey,
        initialUrl: _initialLink,
      ),
    );
  }
}
