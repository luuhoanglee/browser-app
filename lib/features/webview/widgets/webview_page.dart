import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/content_blocker_service.dart';
import '../services/ios_content_blocker_service.dart';
import '../services/webview_interceptor.dart';
import '../../tabs/bloc/tab_bloc.dart';
import '../../tabs/bloc/tab_event.dart';
import '../../../features/download/bloc/download_bloc.dart';
import '../../../features/download/bloc/download_event.dart';
import '../../../../core/utils/media_utils.dart';

enum WebViewErrorType {
  none,
  noInternet,
  hostNotFound,
  connectionRefused,
  timeout,
  sslError,
  genericError,
}

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
  final Function(InAppWebViewController, WebUri?, bool?)? onUpdateVisitedHistory;
  final Function()? onSwipeBack;
  final Function()? onSwipeForward;

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
    this.onSwipeBack,
    this.onSwipeForward,
    this.onUpdateVisitedHistory,
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

  // Error state tracking
  WebViewErrorType _errorType = WebViewErrorType.none;
  String? _errorMessage;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _hadError = false; // Track if error occurred during current load

  // User-Agent chuẩn để tránh bị rate limit
  static const String _iosUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/17.2 Mobile/15E148 Safari/604.1';

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
        supportMultipleWindows: false,
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
      print('[iOS] Settings initialized with ${blockers.length} content blockers');
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
        urlLower.startsWith('opera://') ||
        urlLower.startsWith('x-safari-');
  }

  /// Kiểm tra URL có phải custom scheme không (không phải http/https)
  static bool _isCustomScheme(String url) {
    final urlLower = url.toLowerCase();
    return !urlLower.startsWith('http://') &&
        !urlLower.startsWith('https://') &&
        !urlLower.startsWith('intent://') &&
        !urlLower.startsWith('data:') &&
        !urlLower.startsWith('about:') &&
        urlLower.contains('://');
  }

  /// Chuyển custom scheme sang https
  static String? _convertCustomSchemeToHttps(String url) {
    try {
      final uri = Uri.parse(url);

      // Lấy domain từ scheme (ví dụ: febbox:// → febbox.com)
      final scheme = uri.scheme;
      final domain = '$scheme.com';

      // Ghép path và query params với domain mới
      final path = uri.path;
      final query = uri.hasQuery ? '?${uri.query}' : '';

      final httpsUrl = 'https://$domain$path$query';
      print('[CustomScheme] Converting $url to $httpsUrl');
      return httpsUrl;
    } catch (e) {
      print('[CustomScheme] Failed to convert $url: $e');
      return null;
    }
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

/// Show confirmation dialog before opening external app
Future<bool> _showOpenExternalAppDialog(String url) async {
  final uri = Uri.tryParse(url);
  final scheme = uri?.scheme ?? 'app';
  final appName = scheme.isNotEmpty 
      ? '${scheme[0].toUpperCase()}${scheme.substring(1)}' 
      : 'External App';

  return await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Open in $appName?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This website wants to open a link using $appName.'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              url,
              style: const TextStyle(
                fontSize: 12, 
                color: Colors.blue,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Open'),
        ),
      ],
    ),
  ) ?? false;
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

  
  Future<void> _injectAntiDetectScript(InAppWebViewController controller) async {
    final antiDetectScript = r"""
(function() {
  try {
    const originalEval = window.eval;
    window.eval = function(code) {
      if (typeof code === 'string' && code.includes('debugger')) return;
      return originalEval(code);
    };

    ['log','warn','error','info','debug','trace','clear'].forEach(m => {
      console[m] = function(){};
    });

    Object.defineProperty(window, 'outerHeight', { get: () => window.innerHeight });
    Object.defineProperty(window, 'outerWidth', { get: () => window.innerWidth });

    Object.defineProperty(navigator, 'webdriver', { get: () => false });
    Object.defineProperty(navigator, 'platform', { get: () => 'iPhone' });

    window.location.reload = function(){};
    window.alert = function(){};
    window.confirm = function(){ return true; };

    console.log("✅ Anti-Detect script injected");
  } catch(e) {
    console.log("Anti-Detect Error:", e);
  }
})();
""";

    await controller.addUserScript(
      userScript: UserScript(
        source: antiDetectScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        contentWorld: ContentWorld.PAGE,
      ),
    );
  }

  Future<void> _injectYouTubeAdBlocker(InAppWebViewController controller) async {
    const youtubeAdScript = r'''
      (function() {
        if (!window.location.hostname.includes('youtube.com')) {
          return;
        }

        console.log('[YouTube-AdBlocker] Initializing Enhanced v2.0...');

        // Statistics tracking
        var stats = {
          total: 0,
          fetch: 0,
          xhr: 0,
          cosmetic: 0,
          player: 0
        };

        // Comprehensive ad domains and patterns (like uBlock filter lists)
        const adPatterns = [
          // Ad servers
          'doubleclick.net',
          'googlesyndication.com',
          'googleadservices.com',
          'google-analytics.com',
          'googletagmanager.com',
          'googletagservices.com',

          // YouTube specific
          '/pagead/',
          '/api/stats/ads',
          '/api/stats/atr',
          '/api/stats/qoe',
          '/ptracking',
          '/get_video_info',
          '/youtubei/v1/player/ad',
          '/youtubei/v1/next',
          'ad_break',
          'adformat',
          'ad_flags',
          'ad_video_id',

          // Tracking
          '/log_event',
          '/log_interaction',
          'doubleclick',
          'ad_pod',
          'adunit'
        ];

        // Check if URL contains ad patterns
        function isAdRequest(url) {
          if (typeof url !== 'string') return false;
          const lowerUrl = url.toLowerCase();
          return adPatterns.some(pattern => lowerUrl.includes(pattern.toLowerCase()));
        }

        // ===== NETWORK BLOCKING (like uBlock) =====

        // Block Fetch API
        const originalFetch = window.fetch;
        window.fetch = function(...args) {
          const url = args[0];
          if (isAdRequest(url)) {
            return Promise.reject(new Error('Blocked by AdBlocker'));
          }
          return originalFetch.apply(this, args);
        };

        // Block XMLHttpRequest
        const originalXHROpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function(method, url, ...rest) {
          if (isAdRequest(url)) {
            this.abort();
            return;
          }
          return originalXHROpen.apply(this, [method, url, ...rest]);
        };

        // Block XMLHttpRequest send as backup
        const originalXHRSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.send = function(...args) {
          if (this._blocked) return;
          return originalXHRSend.apply(this, args);
        };

        // ===== PLAYER MODIFICATION (like uBlock) =====

        // Hijack player response to remove ads
        function removeAdsFromPlayerResponse(playerResponse) {
          if (!playerResponse) return playerResponse;

          try {
            // Remove ad placements
            if (playerResponse.adPlacements) {
              delete playerResponse.adPlacements;
              stats.player++;
            }
            if (playerResponse.ads) {
              delete playerResponse.ads;
              stats.player++;
            }
            if (playerResponse.adSlots) {
              delete playerResponse.adSlots;
              stats.player++;
            }

            // Remove playerAds
            if (playerResponse.playerAds) {
              delete playerResponse.playerAds;
              stats.player++;
            }

            // Clean playbackTracking
            if (playerResponse.playbackTracking) {
              const tracking = playerResponse.playbackTracking;
              delete tracking.videostatsPlaybackUrl;
              delete tracking.videostatsDelayplayUrl;
              delete tracking.videostatsWatchtimeUrl;
              delete tracking.ptrackingUrl;
              delete tracking.qoeUrl;
              delete tracking.atrUrl;
            }
          } catch(e) {
            console.log('[YouTube-AdBlocker] Player response clean error:', e.message);
          }

          return playerResponse;
        }

        // Intercept JSON parse for player responses
        const originalParse = JSON.parse;
        JSON.parse = function(text, ...args) {
          const result = originalParse.apply(this, [text, ...args]);

          if (result && typeof result === 'object') {
            // Check if this is a player response
            if (result.adPlacements || result.playerAds || result.ads) {
              removeAdsFromPlayerResponse(result);
            }

            // Check nested responses
            if (result.playerResponse) {
              removeAdsFromPlayerResponse(result.playerResponse);
            }
          }

          return result;
        };

        // ===== COSMETIC FILTERING (like uBlock) =====

        // CSS to hide ad elements
        const adBlockCSS = `
          /* Video ads */
          .video-ads,
          .ytp-ad-module,
          .ytp-ad-overlay-container,
          .ytp-ad-image-overlay,
          .ytp-ad-text-overlay,

          /* Display ads */
          #masthead-ad,
          #player-ads,
          #watch-branded-actions,
          .ytd-merch-shelf-renderer,
          .ytd-ad-slot-renderer,
          ytd-display-ad-renderer,
          ytd-video-masthead-ad-v3-renderer,
          ytd-statement-banner-renderer,
          ytd-ad-slot-renderer,
          yt-mealbar-promo-renderer,

          /* Sidebar ads */
          #right-tabs > .ytd-item-section-renderer,
          ytd-compact-promoted-video-renderer,

          /* Banner ads */
          ytd-banner-promo-renderer,
          ytd-promoted-sparkles-web-renderer,

          /* In-feed ads */
          ytd-ad-slot-renderer,
          ytd-in-feed-ad-layout-renderer,

          /* Overlay ads */
          .ytp-ce-element,
          .ytp-cards-teaser,

          /* Popup ads */
          tp-yt-paper-dialog.ytd-popup-container,
          ytd-popup-container
          {
            display: none !important;
            visibility: hidden !important;
            opacity: 0 !important;
            height: 0 !important;
            width: 0 !important;
            pointer-events: none !important;
          }
        `;

        // Inject CSS
        function injectCSS() {
          const style = document.createElement('style');
          style.id = 'youtube-adblocker-style';
          style.textContent = adBlockCSS;
          document.head.appendChild(style);
          console.log('[YouTube-AdBlocker] CSS injected');
        }

        // Remove ad elements from DOM
        function removeAdElements() {
          const selectors = [
            '.video-ads',
            '.ytp-ad-module',
            '.ytp-ad-overlay-container',
            'ytd-display-ad-renderer',
            'ytd-ad-slot-renderer',
            'ytd-promoted-sparkles-web-renderer',
            'ytd-compact-promoted-video-renderer',
            'ytd-banner-promo-renderer',
            'ytd-in-feed-ad-layout-renderer'
          ];

          let removed = 0;
          selectors.forEach(selector => {
            const elements = document.querySelectorAll(selector);
            elements.forEach(el => {
              if (el && el.parentNode) {
                el.parentNode.removeChild(el);
                removed++;
              }
            });
          });

          if (removed > 0) {
            stats.cosmetic += removed;
          }
        }

        // ===== MUTATION OBSERVER (like uBlock) =====

        // Watch for dynamically added ad elements
        const observer = new MutationObserver(function(mutations) {
          removeAdElements();
        });

        // Start observing when DOM is ready
        function startObserver() {
          if (document.body) {
            observer.observe(document.body, {
              childList: true,
              subtree: true
            });
            console.log('[YouTube-AdBlocker] DOM observer started');
          } else {
            setTimeout(startObserver, 100);
          }
        }

        // ===== INITIALIZATION =====

        // Initialize when DOM is ready
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', function() {
            injectCSS();
            removeAdElements();
            startObserver();
          });
        } else {
          injectCSS();
          removeAdElements();
          startObserver();
        }
        console.log('[YouTube-AdBlocker] Enhanced v2.0 Active!');
      })();
    ''';

    await controller.addUserScript(
      userScript: UserScript(
        source: youtubeAdScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        contentWorld: ContentWorld.PAGE,
      ),
    );
  }

  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    widget.onWebViewCreated(controller);

    // Inject intent blocking script
    await _injectBlockIntentScript(controller);
    await _injectAntiDetectScript(controller);
    await _injectYouTubeAdBlocker(controller);
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

  void _onLoadResourceWithResponse(
    InAppWebViewController controller,
    LoadedResource resource,
  ) {
    final url = resource.url?.toString();
    if (url == null || url.isEmpty) return;

    // Filter media resources only
    if (!MediaUtils.isMedia(url)) return;

    print('[Resource] Media detected: $url');

    // Get the tab ID from activeTab
    final tabId = widget.activeTab?.id;
    if (tabId == null) return;

    // Add to tab's loaded resources via TabBloc
    if (mounted) {
      context.read<TabBloc>().add(AddLoadedResourceEvent(tabId, resource));
    }
  }

  void _onDownloadStart(
    InAppWebViewController controller,
    Uri url,
  ) {
    final urlStr = url.toString();
    final fileName = urlStr.split('/').last;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang tải: ${fileName.isNotEmpty ? fileName : "file"}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Start download using DownloadBloc
    if (mounted) {
      try {
        final downloadBloc = context.read<DownloadBloc>();
        downloadBloc.add(DownloadStartEvent(urlStr, customFileName: fileName.isNotEmpty ? fileName : null));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể bắt đầu tải: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _onLoadStart(InAppWebViewController controller, WebUri? url) {
    if (url != null) {
      final urlStr = url.toString();

      print('[onLoadStart] URL: $urlStr');
      print('[onLoadStart] Resetting _hadError to false');

      _hadError = false;

      // Clear previous loaded resources when starting new main frame load
      final tabId = widget.activeTab?.id;
      if (tabId != null && mounted) {
        context.read<TabBloc>().add(ClearLoadedResourcesEvent(tabId));
      }

      // Clear previous error when starting new load
      if (_errorType != WebViewErrorType.none) {
        print('[onLoadStart] Clearing previous error state');
        _clearError();
      }

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

      if (Platform.isAndroid && urlStr.isNotEmpty) {
        WebViewInterceptor.setCurrentDomain(urlStr);
        WebViewInterceptor.handleLoadStart(controller, url);
      }
    }

    widget.onLoadStart(controller, url);
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    final urlStr = url?.toString() ?? '';

    print('[onLoadStop] URL: $urlStr');
    print('[onLoadStop] Current error type: $_errorType');
    print('[onLoadStop] _hadError: $_hadError');

    if (_hadError) {
      print('[onLoadStop] Error occurred during load, keeping error state');
      return;
    }

    if (Platform.isAndroid && urlStr.isNotEmpty) {
      WebViewInterceptor.setCurrentDomain(urlStr);
      WebViewInterceptor.injectAntiPopupJS(controller);
    }

    // Clear error when page loads successfully
    _clearError();

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

  
    if (_isCustomScheme(url)) {
      final shouldOpen = await _showOpenExternalAppDialog(url);
      if (shouldOpen) {
        try {
          final launched = await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No app found to open this link'),
                  duration: Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot open app: $e'),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
      return NavigationActionPolicy.CANCEL;
    }

    // Block external URLs
    if (_isExternalUrl(url)) {
      return NavigationActionPolicy.CANCEL;
    }

    // iOS: Allow all navigation
    if (Platform.isIOS) {
      return NavigationActionPolicy.ALLOW;
    }

    // Android: Use interceptor
    return WebViewInterceptor.shouldOverrideUrlLoading(controller, navigationAction);
  }

  Future<bool> _onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  ) async {
    if (Platform.isIOS) {
      return true;
    }
    return await WebViewInterceptor.handleCreateWindow(controller, createWindowAction);
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

  void _onReceivedHttpError(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceResponse response,
  ) {
    if (request.isForMainFrame != true) return;

    _hadError = true;

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

    print('[onReceivedHttpError] Status: ${response.statusCode}');
    print('[onReceivedHttpError] URL: $url');

    if (_isOffline) {
      _setError(WebViewErrorType.noInternet, 'No internet connection');
    } else if (response.statusCode == 404) {
      _setError(WebViewErrorType.hostNotFound, 'Page not found');
    } else if (response.statusCode != null && response.statusCode! >= 500) {
      _setError(WebViewErrorType.connectionRefused, 'Server error');
    } else {
      _setError(WebViewErrorType.genericError, 'Failed to load page (code ${response.statusCode})');
    }
  }

  void _onReceivedError(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceError error,
  ) {
    if (request.isForMainFrame != true) return;

    if (error.type == WebResourceErrorType.CANCELLED) {
      return;
    }

    final url = request.url.toString();

    _hadError = true;

    controller.stopLoading();

    WebViewErrorType errorType;
    String message;

    if (error.type == WebResourceErrorType.HOST_LOOKUP) {
      errorType = WebViewErrorType.hostNotFound;
      message = 'Address not found';
    } else if (error.type == WebResourceErrorType.TIMEOUT) {
      errorType = WebViewErrorType.timeout;
      message = 'Connection timeout';
    } else if (error.type == WebResourceErrorType.NETWORK_CONNECTION_LOST || error.description.toString().contains('connection was lost')) {
      errorType = WebViewErrorType.noInternet;
      message = 'Network connection lost';
    } else if (_isOffline && (error.description.toString().contains('INTERNET') || error.description.toString().contains('network'))) {
      errorType = WebViewErrorType.noInternet;
      message = 'No internet connection';
    } else {
      errorType = WebViewErrorType.genericError;
      message = error.description ?? 'An error occurred';
    }

    _setError(errorType, message);
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final isOffline = results.every((result) => result == ConnectivityResult.none);
    if (_isOffline != isOffline) {
      setState(() {
        _isOffline = isOffline;
        if (isOffline) {
          _errorType = WebViewErrorType.noInternet;
          _errorMessage = 'No internet connection';
        } else {
          _clearError();
        }
      });
    }
  }

  void _clearError() {
    if (_errorType != WebViewErrorType.none) {
      print('[WebViewError] Clearing error state');
    }
    setState(() {
      _errorType = WebViewErrorType.none;
      _errorMessage = null;
    });
  }

  void _setError(WebViewErrorType type, String message) {
    print('[WebViewError] Setting error: $type - $message');
    print('[WebViewError] Stack trace: ${StackTrace.current}');
    setState(() {
      _errorType = type;
      _errorMessage = message;
    });
  }

  @override
  void initState() {
    super.initState();
    _initFuture ??= _initializeCache();
    _checkConnectivity();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOffline = results.every((result) => result == ConnectivityResult.none);
      setState(() {
        _isOffline = isOffline;
        if (isOffline) {
          _errorType = WebViewErrorType.noInternet;
          _errorMessage = 'No internet connection';
        } else if (_errorType == WebViewErrorType.noInternet) {
          _clearError();
        }
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Widget _buildErrorWidget() {
    IconData icon;
    Color iconColor;
    String title;
    String subtitle;

    switch (_errorType) {
      case WebViewErrorType.noInternet:
        icon = Icons.wifi_off;
        iconColor = Colors.orange;
        title = 'No Internet Connection';
        subtitle = 'Please check your internet connection';
        break;
      case WebViewErrorType.hostNotFound:
        icon = Icons.search_off;
        iconColor = Colors.red;
        title = 'Page Not Found';
        subtitle = 'The webpage address does not exist';
        break;
      case WebViewErrorType.connectionRefused:
        icon = Icons.cloud_off;
        iconColor = Colors.red;
        title = 'Connection Refused';
        subtitle = 'The server refused the connection';
        break;
      case WebViewErrorType.timeout:
        icon = Icons.access_time;
        iconColor = Colors.orange;
        title = 'Connection Timeout';
        subtitle = 'The server is taking too long to respond. Please try again';
        break;
      case WebViewErrorType.sslError:
        icon = Icons.lock_open;
        iconColor = Colors.red;
        title = 'Security Error';
        subtitle = 'The connection is not secure';
        break;
      case WebViewErrorType.genericError:
      default:
        icon = Icons.error_outline;
        iconColor = Colors.grey;
        title = 'An Error Occurred';
        subtitle = _errorMessage ?? 'Unable to load page';
        break;
    }

    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: iconColor),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Reset error flag before retry
                  _hadError = false;
                  _clearError();

                  // Trigger reload via callback if controller exists
                  if (widget.controller != null) {
                    widget.controller!.reload();
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final initialUrl = _getInitialUrl();

    return RepaintBoundary(
      child: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          return Stack(
            children: [
              Opacity(
                opacity: _errorType == WebViewErrorType.none ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: _errorType != WebViewErrorType.none,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: InAppWebView(
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
                      onLoadResource: _onLoadResourceWithResponse,
                      onDownloadStart: _onDownloadStart,
                      onDownloadStartRequest: (controller, request) {
                        _onDownloadStart(controller, request.url);
                      },
                      onTitleChanged: (controller, title) => widget.onTitleChanged(controller, title),
                      onProgressChanged: (controller, progress) =>
                          widget.onProgressChanged(controller, progress),
                      onScrollChanged: (controller, x, y) => widget.onScrollChanged(y),
                      shouldInterceptRequest: _shouldInterceptRequest,
                      shouldInterceptAjaxRequest: _shouldInterceptAjaxRequest,
                      shouldInterceptFetchRequest: _shouldInterceptFetchRequest,
                      shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
                      onCreateWindow: _onCreateWindow,
                      onReceivedError: _onReceivedError,
                      onReceivedHttpError: _onReceivedHttpError,
                      onUpdateVisitedHistory: widget.onUpdateVisitedHistory,
                    ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorType == WebViewErrorType.none)
                Positioned.fill(
                  child: _FullScreenSwipeZone(
                    onSwipeBack: widget.onSwipeBack,
                    onSwipeForward: widget.onSwipeForward,
                  ),
                ),
              // if (_errorType != WebViewErrorType.none)
              //   Positioned.fill(
              //     child: _buildErrorWidget(),
              //   ),
            ],
          );
        },
      ),
    );
  }
}

class _FullScreenSwipeZone extends StatefulWidget {
  final VoidCallback? onSwipeBack;
  final VoidCallback? onSwipeForward;

  const _FullScreenSwipeZone({
    this.onSwipeBack,
    this.onSwipeForward,
  });

  @override
  State<_FullScreenSwipeZone> createState() => _FullScreenSwipeZoneState();
}

class _FullScreenSwipeZoneState extends State<_FullScreenSwipeZone> {
  double? _startX;
  double? _startY;

  static const double _minDistance = 50;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _startX = event.position.dx;
        _startY = event.position.dy;
      },
      onPointerUp: (event) {
        if (_startX == null || _startY == null) return;

        final endX = event.position.dx;
        final endY = event.position.dy;
        final diffX = endX - _startX!;
        final diffY = endY - _startY!;
        final horizontalDistance = diffX.abs();
        final verticalDistance = diffY.abs();

        final isHorizontalSwipe = horizontalDistance > verticalDistance;

        if (!isHorizontalSwipe) {
          _startX = null;
          _startY = null;
          return;
        }

        if (horizontalDistance < _minDistance) {
          _startX = null;
          _startY = null;
          return;
        }

        if (diffX < 0) {
          widget.onSwipeBack?.call();
        } else {
          widget.onSwipeForward?.call();
        }

        _startX = null;
        _startY = null;
      },
      child: const SizedBox.shrink(),
    );
  }
}