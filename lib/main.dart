import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/pages/home/home_page.dart';

void main() {
  runApp(const BrowserApp());
}

// GlobalKey để truy cập HomeView từ bên ngoài
final GlobalKey<HomeViewWrapperState> homeViewKey = GlobalKey<HomeViewWrapperState>();

class BrowserApp extends StatefulWidget {
  const BrowserApp({super.key});

  @override
  State<BrowserApp> createState() => _BrowserAppState();
}

class _BrowserAppState extends State<BrowserApp> {
  static const _channel = MethodChannel('com.dino.blackdogbrowser.browser_app/deeplink');
  String? _initialLink;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
    _getInitialLink();
  }

  Future<void> _getInitialLink() async {
    try {
      final String? link = await _channel.invokeMethod('getInitialLink');
      if (link != null && mounted) {
        setState(() {
          _initialLink = link;
        });
      }
    } catch (e) {
      print('❌ Error getting initial link: $e');
    }
  }

  void _initDeepLinkListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final String url = call.arguments as String;
        print('🔗 Deep link received (app running): $url');
        // Load URL vào HomeView
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomePage(
        key: homeViewKey,
        initialUrl: _initialLink,
      ),
    );
  }
}
