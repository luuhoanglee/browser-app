import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Mixin that manages status-bar / system-UI chrome based on the active tab's
/// theme colour and incognito state.
mixin StatusBarMixin {
  final Map<String, Color> _tabThemeColors = {};

  /// Returns the cached theme colour for [tabId], or null if not recorded.
  Color? tabThemeColor(String tabId) => _tabThemeColors[tabId];

  void updateStatusBar({Color? themeColor, required bool isIncognito}) {
    final SystemUiOverlayStyle style;
    if (isIncognito) {
      style = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      );
    } else if (themeColor != null) {
      final isDark = themeColor.computeLuminance() < 0.179;
      style = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      );
    } else {
      style = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      );
    }
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  Future<void> syncSystemUiFromWebPage({
    required InAppWebViewController controller,
    required String tabId,
    required bool isIncognito,
  }) async {
    if (isIncognito) {
      _tabThemeColors.remove(tabId);
      updateStatusBar(themeColor: null, isIncognito: true);
      return;
    }

    try {
      final jsResult = await controller.evaluateJavascript(
        source: '''
        (function() {
          function pickColor(el) {
            if (!el) return '';
            var bg = window.getComputedStyle(el).backgroundColor || '';
            if (!bg || bg === 'transparent' || bg === 'rgba(0, 0, 0, 0)') return '';
            return bg;
          }
          return pickColor(document.body) || pickColor(document.documentElement) || '';
        })();
      ''',
      );

      String cssColor = '';
      if (jsResult is String) {
        cssColor = jsResult;
      } else if (jsResult != null) {
        cssColor = jsResult.toString();
      }

      final color = parseCssColor(cssColor);
      if (color != null) {
        _tabThemeColors[tabId] = color;
      } else {
        _tabThemeColors.remove(tabId);
      }

      updateStatusBar(
        themeColor: _tabThemeColors[tabId],
        isIncognito: isIncognito,
      );
    } catch (_) {
      updateStatusBar(
        themeColor: _tabThemeColors[tabId],
        isIncognito: isIncognito,
      );
    }
  }

  Color? parseCssColor(String css) {
    css = css.trim();
    if (css.startsWith('"') && css.endsWith('"') && css.length >= 2) {
      css = css.substring(1, css.length - 1);
    }
    if (css.startsWith('#')) {
      final hex = css.substring(1);
      if (hex.length == 3) {
        final r = int.parse('${hex[0]}${hex[0]}', radix: 16);
        final g = int.parse('${hex[1]}${hex[1]}', radix: 16);
        final b = int.parse('${hex[2]}${hex[2]}', radix: 16);
        return Color.fromARGB(255, r, g, b);
      } else if (hex.length == 6) {
        final v = int.tryParse(hex, radix: 16);
        if (v != null) return Color(0xFF000000 | v);
      }
    }
    final rgb = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)').firstMatch(css);
    if (rgb != null) {
      return Color.fromARGB(
        255,
        int.parse(rgb.group(1)!),
        int.parse(rgb.group(2)!),
        int.parse(rgb.group(3)!),
      );
    }
    final rgba = RegExp(
      r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([0-9]*\.?[0-9]+)\)',
    ).firstMatch(css);
    if (rgba != null) {
      final alpha = double.tryParse(rgba.group(4)!) ?? 1.0;
      if (alpha <= 0) return null;
      return Color.fromARGB(
        (alpha * 255).round().clamp(0, 255),
        int.parse(rgba.group(1)!),
        int.parse(rgba.group(2)!),
        int.parse(rgba.group(3)!),
      );
    }
    return null;
  }
}
