import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/content_blocker_service.dart';
import '../services/ios_content_blocker_service.dart';
import '../services/webview_interceptor.dart';

class WebViewPage extends StatefulWidget {
  final dynamic activeTab;
  final InAppWebViewController? controller;
  final PullToRefreshController? pullToRefreshController;
  final Function(InAppWebViewController) onWebViewCreated;
  final Function(InAppWebViewController, WebUri?) onLoadStart;
  final Function(InAppWebViewController, WebUri?) onLoadStop;
  final Function(InAppWebViewController, String?) onTitleChanged;
  final Function(InAppWebViewController, int) onProgressChanged;
  final Function(int) onScrollChanged;
  final Function(String)? onUrlUpdated;

  const WebViewPage({
    super.key,
    required this.activeTab,
    required this.controller,
    this.pullToRefreshController,
    required this.onWebViewCreated,
    required this.onLoadStart,
    required this.onLoadStop,
    required this.onTitleChanged,
    required this.onProgressChanged,
    required this.onScrollChanged,
    this.onUrlUpdated,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  // Cache settings to avoid recreating on every build
  static InAppWebViewSettings? _cachedSettings;
  static bool _isInitialized = false;
  static Future<void>? _initFuture; // Cache the init future

  static Future<void> _initializeCache() async {
    if (_isInitialized) return;

    // 🔥 Initialize AdBlocker patterns from file - async to avoid blocking
    try {
      // For Android
      await ContentBlockerService.initialize();
      debugPrint('✅ [ContentBlocker] Initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize ContentBlocker: $e');
    }

    // iOS-specific settings for Content Blocker
    if (Platform.isIOS) {
      // 📱 Load rules from assets/blockerList.json for iOS
      try {
        await IOSContentBlockerService.initialize();
        final blockers = await IOSContentBlockerService.getContentBlockers();
        debugPrint('📱 [iOS] Setting up ${blockers.length} content blockers');

        _cachedSettings = InAppWebViewSettings(
          disallowOverScroll: false,
          useShouldOverrideUrlLoading: true,
          useOnLoadResource: true,
          useOnDownloadStart: true,
          useShouldInterceptRequest: true,
          useShouldInterceptAjaxRequest: true,
          useShouldInterceptFetchRequest: true,
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: false,
          supportMultipleWindows: false,
          hardwareAcceleration: true,
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsLinkPreview: false,
          userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          // Performance optimizations
          cacheEnabled: true,
          clearCache: false,
          databaseEnabled: true,
          domStorageEnabled: true,
          // iOS Content Blocker from List<ContentBlocker>
          contentBlockers: blockers,
        );
      } catch (e) {
        debugPrint('⚠️ [iOS] Failed to load content blockers: $e');
        _cachedSettings = InAppWebViewSettings(
          disallowOverScroll: false,
          useShouldOverrideUrlLoading: true,
          useOnLoadResource: true,
          useOnDownloadStart: true,
          useShouldInterceptRequest: true,
          useShouldInterceptAjaxRequest: true,
          useShouldInterceptFetchRequest: true,
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: false,
          supportMultipleWindows: false,
          hardwareAcceleration: true,
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsLinkPreview: false,
          userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          cacheEnabled: true,
          clearCache: false,
          databaseEnabled: true,
          domStorageEnabled: true,
        );
      }
    } else {
      _cachedSettings = InAppWebViewSettings(
        disallowOverScroll: false,
        useShouldOverrideUrlLoading: true,
        useOnLoadResource: true,
        useOnDownloadStart: true,
        useShouldInterceptRequest: true,
        useShouldInterceptAjaxRequest: true,
        useShouldInterceptFetchRequest: true,
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: false,
        supportMultipleWindows: false,
        hardwareAcceleration: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
        cacheEnabled: true,
        clearCache: false,
        databaseEnabled: true,
        domStorageEnabled: true,
      );
    }

    _isInitialized = true;
  }

  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    widget.onWebViewCreated(controller);

    final initialUrl = _getInitialUrl();
    if (initialUrl.isNotEmpty) {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(initialUrl)));
    }
  }

  String _getInitialUrl() {
    String url = widget.activeTab.url ?? '';

    if (url.isEmpty) return '';

    if (url.startsWith('intent://')) {
      final parsed = _parseIntentUrl(url);
      if (parsed != null) {
        widget.onUrlUpdated?.call(parsed);
        return parsed;
      }
      widget.onUrlUpdated?.call('');
      return '';
    }

    // Block external URLs
    if (_isExternalUrl(url)) {
      widget.onUrlUpdated?.call('');
      return '';
    }

    return url;
  }

  void _onLoadStart(InAppWebViewController controller, WebUri? url) {
    if (url != null && url.toString().isNotEmpty) {
      WebViewInterceptor.setCurrentDomain(url.toString());
    }

    WebViewInterceptor.handleLoadStart(controller, url);
    widget.onLoadStart(controller, url);
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    final urlStr = url?.toString() ?? 'unknown';
    print('🔄 [WebViewPage] onLoadStop: $urlStr');

    if (url != null && urlStr.isNotEmpty) {
      WebViewInterceptor.setCurrentDomain(urlStr);
    }

    WebViewInterceptor.injectAntiPopupJS(controller);

    widget.onLoadStop(controller, url);
  }

  NavigationActionPolicy _shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) {
    return WebViewInterceptor.shouldOverrideUrlLoading(controller, navigationAction);
  }

  Future<bool> _onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  ) async {
    return await WebViewInterceptor.handleCreateWindow(controller, createWindowAction);
  }

  static String? _scheme(String url) {
    final i = url.indexOf('://');
    return i == -1 ? null : url.substring(0, i).toLowerCase();
  }

  static bool _isExternalUrl(String url) {
    final scheme = _scheme(url.toLowerCase());
    const externalSchemes = {'googlechrome', 'chrome', 'firefox', 'edge', 'opera'};
    return scheme != null && externalSchemes.contains(scheme);
  }

  static String? _parseIntentUrl(String url) {
    try {
      final i = url.indexOf('#Intent');
      if (i == -1) return null;

      final main = url.substring(0, i).replaceFirst('intent://', 'https://');
      if (main.startsWith('https://') || main.startsWith('http://')) {
        return main;
      }
    } catch (_) {}
    return null;
  }

  WebResourceResponse? _shouldInterceptRequest(
    InAppWebViewController controller,
    WebResourceRequest request,
  ) {
    return WebViewInterceptor.interceptRequest(request);
  }

  Future<AjaxRequest?> _shouldInterceptAjaxRequest(
    InAppWebViewController controller,
    AjaxRequest request,
  ) async {
    return await WebViewInterceptor.shouldInterceptAjaxRequest(request);
  }

  Future<FetchRequest?> _shouldInterceptFetchRequest(
    InAppWebViewController controller,
    FetchRequest request,
  ) async {
    return await WebViewInterceptor.shouldInterceptFetchRequest(request);
  }

  @override
  void initState() {
    super.initState();
    _initFuture ??= _initializeCache();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final initialUrl = _getInitialUrl();

    return RepaintBoundary(
      child: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          return InAppWebView(
            key: ValueKey(widget.activeTab.id),
            initialUrlRequest: initialUrl.isEmpty
                ? null
                : URLRequest(url: WebUri(initialUrl)),
            initialSettings: _cachedSettings,
            pullToRefreshController: widget.pullToRefreshController,
            onWebViewCreated: _onWebViewCreated,
            onLoadStart: _onLoadStart,
            onLoadStop: _onLoadStop,
            onTitleChanged: (controller, title) => widget.onTitleChanged(controller, title),
            onProgressChanged: (controller, progress) =>
                widget.onProgressChanged(controller, progress),
            onScrollChanged: (controller, x, y) => widget.onScrollChanged(y),
            shouldInterceptRequest: _shouldInterceptRequest,
            shouldInterceptAjaxRequest: _shouldInterceptAjaxRequest,
            shouldInterceptFetchRequest: _shouldInterceptFetchRequest,
            shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
            onCreateWindow: _onCreateWindow,
          );
        },
      ),
    );
  }
}