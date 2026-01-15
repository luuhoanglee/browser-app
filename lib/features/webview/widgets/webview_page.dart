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

  static InAppWebViewSettings? _cachedSettings;
  static bool _isInitialized = false;
  static Future<void>? _initFuture;

  static const String _iosUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
      '(KHTML, like Gecko) Version/17.2 Safari/605.1.15';

  static const String _androidUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  static Future<void> _initializeCache() async {
    if (_isInitialized) return;

    if (Platform.isIOS) {
      final blockers = IOSContentBlockerService.getContentBlockers();
      _cachedSettings = InAppWebViewSettings(
        disallowOverScroll: false,
        useShouldOverrideUrlLoading: true,
        useOnLoadResource: true,
        useOnDownloadStart: true,
        useShouldInterceptRequest: false,
        useShouldInterceptAjaxRequest: true,
        useShouldInterceptFetchRequest: true,
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: false,
        supportMultipleWindows: true,
        hardwareAcceleration: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsLinkPreview: false,
        cacheEnabled: true,
        databaseEnabled: true,
        domStorageEnabled: true,
        userAgent: _iosUserAgent,
        applicationNameForUserAgent: '',
        contentBlockers: blockers,
      );
      print('[iOS] Settings initialized with WebViewInterceptor support');
    } else {
      try {
        await ContentBlockerService.initialize();
        debugPrint('[Android] ContentBlocker initialized');
      } catch (e) {
        debugPrint('[Android] Failed to initialize ContentBlocker: $e');
      }

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
        userAgent: _androidUserAgent,
        applicationNameForUserAgent: '',
        cacheEnabled: true,
        clearCache: false,
        databaseEnabled: true,
        domStorageEnabled: true,
        contentBlockers: ContentBlockerService.createAdBlockers(),
      );
      debugPrint('[Android] Settings initialized');
    }

    _isInitialized = true;
  }

  /// Parse intent:// URL thành https:// URL
  static String? _parseIntentUrl(String url) {
    if (!url.startsWith('intent://')) return null;

    try {
      final uriParts = url.split('#Intent');
      if (uriParts.isEmpty) return null;

      String targetUrl = uriParts[0].replaceFirst('intent://', 'https://');

      // Parse scheme parameter
      final intentParams = uriParts.length > 1 ? uriParts[1] : '';
      final schemeMatch = RegExp(r'scheme=([^;]+)').firstMatch(intentParams);

      if (schemeMatch != null) {
        final scheme = schemeMatch.group(1);
        if (scheme != null && scheme != 'http' && scheme != 'https') {
          return null; // Non-web scheme, skip
        }
      }

      return targetUrl;
    } catch (e) {
      debugPrint('Error parsing intent URL: $e');
      return null;
    }
  }

  /// Kiểm tra URL có phải external scheme không
  static bool _isExternalUrl(String url) {
    final urlLower = url.toLowerCase();
    return urlLower.startsWith('intent://') ||
        urlLower.startsWith('googlechrome://') ||
        urlLower.startsWith('firefox://') ||
        urlLower.startsWith('chrome://') ||
        urlLower.startsWith('edge://') ||
        urlLower.startsWith('opera://');
  }

  String _getInitialUrl() {
    String url = widget.activeTab.url ?? '';
    if (url.isEmpty) return '';

    // Handle intent URLs
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

  Map<String, String> _getHeaders(String url) {
    final uri = Uri.parse(url);

    return {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,'
          'image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Cache-Control': 'max-age=0',
      if (uri.host.contains('google')) 'Referer': 'https://www.google.com/',
    };
  }

  Future<void> _injectBlockIntentScript(InAppWebViewController controller) async {
    const blockIntentScript = '''
      (function() {
        const originalLocation = window.location;
        Object.defineProperty(window, 'location', {
          get: function() { return originalLocation; },
          set: function(url) {
            if (typeof url === 'string' && url.startsWith('intent://')) {
              console.log('Blocked intent redirect:', url);
              const match = url.match(/intent:\\/\\/([^#]+)/);
              if (match) {
                const targetUrl = 'https://' + match[1];
                console.log('Redirecting to:', targetUrl);
                originalLocation.href = targetUrl;
              }
              return;
            }
            originalLocation.href = url;
          }
        });
      })();
    ''';

    await controller.addUserScript(
      userScript: UserScript(
        source: blockIntentScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        contentWorld: ContentWorld.PAGE,
      ),
    );
  }

  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    widget.onWebViewCreated(controller);

    // Inject intent blocking script
    await _injectBlockIntentScript(controller);

    final initialUrl = _getInitialUrl();
    if (initialUrl.isNotEmpty) {
      await controller.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(initialUrl),
          headers: _getHeaders(initialUrl),
        ),
      );
    }
  }

  void _onLoadStart(InAppWebViewController controller, WebUri? url) {
    if (url != null) {
      final urlStr = url.toString();

      // Handle intent URLs
      if (urlStr.startsWith('intent://')) {
        final parsed = _parseIntentUrl(urlStr);
        if (parsed != null) {
          controller.stopLoading();
          Future.delayed(const Duration(milliseconds: 100), () {
            controller.loadUrl(
              urlRequest: URLRequest(
                url: WebUri(parsed),
                headers: _getHeaders(parsed),
              ),
            );
          });
          return;
        }
      }

      // Use interceptor for ad blocking
      if (urlStr.isNotEmpty) {
        WebViewInterceptor.setCurrentDomain(urlStr);
        WebViewInterceptor.handleLoadStart(controller, url);
      }
    }

    widget.onLoadStart(controller, url);
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    final urlStr = url?.toString() ?? '';

    if (urlStr.isNotEmpty) {
      WebViewInterceptor.setCurrentDomain(urlStr);
      WebViewInterceptor.injectAntiPopupJS(controller);
    }

    widget.onLoadStop(controller, url);
  }

  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    final url = navigationAction.request.url.toString();

    // Handle intent URLs
    if (url.startsWith('intent://')) {
      final parsed = _parseIntentUrl(url);
      if (parsed != null) {
        await controller.loadUrl(
          urlRequest: URLRequest(
            url: WebUri(parsed),
            headers: _getHeaders(parsed),
          ),
        );
        return NavigationActionPolicy.CANCEL;
      }
      return NavigationActionPolicy.CANCEL;
    }

    // Block external URLs
    if (_isExternalUrl(url)) {
      return NavigationActionPolicy.CANCEL;
    }

    // iOS: Use WebViewInterceptor
    // Android: Use WebViewInterceptor
    return WebViewInterceptor.shouldOverrideUrlLoading(controller, navigationAction);
  }

  Future<bool> _onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  ) async {
    return await WebViewInterceptor.handleCreateWindow(controller, createWindowAction);
  }

  WebResourceResponse? _shouldInterceptRequest(
    InAppWebViewController controller,
    WebResourceRequest request,
  ) {
    if (Platform.isIOS) return null;
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

  void _onReceivedHttpError(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceResponse response,
  ) {

    final url = request.url.toString();

    // Skip ads/tracking errors
    const ignoredPatterns = [
      'doubleclick.net',
      'google-analytics.com',
      'googletagmanager.com',
      'facebook.com/tr',
      'ads',
      'tracker',
      'pixel',
      'analytics',
    ];

    if (ignoredPatterns.any((pattern) => url.contains(pattern))) {
      return;
    }

    print('🔴 [${Platform.isIOS ? "iOS" : "Android"}] HTTP ${response.statusCode}');
    print('   URL: $url');
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
                : URLRequest(
                    url: WebUri(initialUrl),
                    headers: _getHeaders(initialUrl),
                  ),
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
            onReceivedError: (controller, request, error) {
              if (request.isForMainFrame == true) {
                print('❌ [${Platform.isIOS ? "iOS" : "Android"}] ${error.description}');
                print('   URL: ${request.url}');
              }
            },
            onReceivedHttpError: _onReceivedHttpError,
          );
        },
      ),
    );
  }
}