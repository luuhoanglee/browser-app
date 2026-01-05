import 'dart:typed_data';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewControllerManager {
  WebViewControllerManager._();

  static final WebViewControllerManager _instance = WebViewControllerManager._();
  static WebViewControllerManager get instance => _instance;

  final Map<String, InAppWebViewController> _controllers = {};

  /// Get controller for specific tab
  InAppWebViewController? getController(String? tabId) {
    if (tabId == null) return null;
    return _controllers[tabId];
  }

  /// Set controller for specific tab
  void setController(String tabId, InAppWebViewController controller) {
    _controllers[tabId] = controller;
  }

  /// Remove controller for specific tab
  void removeController(String tabId) {
    _controllers.remove(tabId);
  }

  /// Check if controller exists for tab
  bool hasController(String tabId) {
    return _controllers.containsKey(tabId);
  }

  /// Clear all controllers
  void clearAll() {
    _controllers.clear();
  }

  /// Get all controllers
  Map<String, InAppWebViewController> getAllControllers() {
    return Map.from(_controllers);
  }

  /// Navigate back in current tab
  Future<bool> goBack(String? tabId) async {
    final controller = getController(tabId);
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return true;
    }
    return false;
  }

  /// Navigate forward in current tab
  Future<bool> goForward(String? tabId) async {
    final controller = getController(tabId);
    if (controller != null && await controller.canGoForward()) {
      await controller.goForward();
      return true;
    }
    return false;
  }

  /// Refresh current page
  Future<void> reload(String? tabId) async {
    final controller = getController(tabId);
    if (controller != null) {
      await controller.reload();
    }
  }

  /// Load URL in specific tab
  Future<void> loadUrl(String tabId, String url) async {
    final controller = getController(tabId);
    if (controller != null) {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
  }

  /// Take screenshot of current page
  Future<Uint8List?> takeScreenshot(String? tabId) async {
    final controller = getController(tabId);
    if (controller != null) {
      return await controller.takeScreenshot();
    }
    return null;
  }
}
