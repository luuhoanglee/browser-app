import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:browser_app/core/logger/app_logger.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

class DeepLink {
  static String link = kIsWeb ? "http://localhost:8080" : "satreps://app";

  static void initialize() {
    final appLinks = AppLinks();

    if (kIsWeb) {
      GoRouter.optionURLReflectsImperativeAPIs = true;
      usePathUrlStrategy();
    }

    appLinks.uriLinkStream.listen((uri) {
      if (!kIsWeb) {
        AppLogger.debug('DeepLink', 'Segments: ${uri.pathSegments}');
        if (uri.pathSegments.isEmpty) {
          return;
        }
      }

    });
  }
}