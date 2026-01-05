import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TabThumbnailService {
  TabThumbnailService._();

  /// Capture thumbnail from WebView controller
  static Future<Uint8List?> captureFromWebView(
    InAppWebViewController controller,
  ) async {
    try {
      return await controller.takeScreenshot();
    } catch (e) {
      return null;
    }
  }

  /// Capture thumbnail from RepaintBoundary widget
  static Future<Uint8List?> captureFromWidget(
    GlobalKey key, {
    double pixelRatio = 0.3,
  }) async {
    try {
      if (key.currentContext == null) {
        return null;
      }

      RenderObject? renderObject = key.currentContext!.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        return null;
      }

      RenderRepaintBoundary boundary = renderObject as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Generate placeholder thumbnail based on URL
  static Uint8List? generatePlaceholder(String url) {
    // For now, return null. Could be implemented to generate
    // a simple colored image with first letter of domain
    return null;
  }

  /// Compress thumbnail to reduce memory usage
  static Future<Uint8List?> compressThumbnail(
    Uint8List bytes, {
    int maxWidth = 200,
    int quality = 85,
  }) async {
    // For now, just return original bytes
    // Could implement actual compression using image package
    return bytes;
  }
}
