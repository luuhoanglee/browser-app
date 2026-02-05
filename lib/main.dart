import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:browser_app/core/services/local_notification_service.dart';
import 'package:browser_app/data/services/download_notification_service.dart';
import 'presentation/pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lấy theme hiện tại của thiết bị
  final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

  final iconBrightness = brightness == Brightness.dark
      ? Brightness.light 
      : Brightness.dark;

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    statusBarBrightness: brightness, // cho iOS
  ));
  runApp(const BrowserApp());

  _initBackgroundServices();
}

void _initBackgroundServices() {
  Future.microtask(() async {
    try {
      await LocalNotificationService().initialize();
      await DownloadNotificationService().initialize();
    } catch (e) {
      print("❌ Background init error: $e");
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
      MethodChannel('com.dino.blackdogbrowser.browser_app/deeplink');

  String? _initialLink;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinkListener();
      _getInitialLink();
    });

    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      _updateStatusBarStyle();
    };
  }

  void _updateStatusBarStyle() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final iconBrightness = brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: brightness,
    ));
  }

  Future<void> _getInitialLink() async {
    try {
      final String? link = await _channel.invokeMethod('getInitialLink');
      if (link != null && mounted) {
        setState(() => _initialLink = link);
      }
    } catch (e) {
      print('❌ Error getting initial link: $e');
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
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

    return MaterialApp(
      title: 'Browser App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: brightness,
        ),
        useMaterial3: true,
      ),
      home: HomePage(
        key: homeViewKey,
        initialUrl: _initialLink,
      ),
    );
  }
}
