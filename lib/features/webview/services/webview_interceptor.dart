import 'dart:typed_data';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'content_blocker_service.dart';

class WebViewInterceptor {
  WebViewInterceptor._();

  static const Set<String> _safeSchemes = {
    'http', 'https', 'file', 'data', 'about', 'javascript', 'ws', 'wss'
  };

  static const List<String> _externalSchemes = [
    'googlechrome://', 'firefox://', 'chrome://', 'edge://', 'opera://',
    'intent://', 'market://'
  ];

  static const List<String> _aggressiveSites = [
    'fmovies','123movies','putlocker','gomovies','yesmovies',
    'phimmoi','anime','xmovies','hdmovies','watch','stream',
    'motphim','phim14','phim3s','bilutv','animehay','aquareader'
  ];

  static const List<String> _hardBlockedDomains = [
    // Original
    'knowledgeable-let.com',
    'gotrackier.com',
    'appmontize.com',
    'oclaserver.com',
    'pubfuture-ad.com',
    'al5sm.com',
    '255md.com',

    // ⭐ ACS Ad Network - THE MAIN CULPRIT!
    'acscdn.com',
    'acsbcdn.com',
    'acs86.com',
    'flinchrecyclingrouting.com',
    'astronautlividlyreformer.com',
    'notificationpushmonetization.com',
    'pushmonetization.com',

    // Common ad networks
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'adnxs.com',
    'advertising.com',
    'criteo.com',
    'taboola.com',
    'outbrain.com',
    'sfaobvfic.in',
    'revcontent.com',
    'propellerads.com',
    'popads.net',
    'popcash.net',
    'adsterra.com',
    'exoclick.com',
    'juicyads.com',
    'trafficjunky.com',

    // Vietnamese ad networks
    'admicro.vn',
    'adsplay.net',
    'vcmedia.vn',
    'sohoad.vn',

    // Analytics/Trackers
    'hotjar.com',
    'mouseflow.com',
    'inspectlet.com',
    'segment.io',
    'mixpanel.com',

    // Crypto miners
    'coinhive.com',
    'coin-hive.com',
    'jsecoin.com',
    'cryptoloot.pro',

    // Redirect spam
    'popunderjs.com',
    'adnetwork.vn',

    // 🔥 Redirect/Tracking domains (from logs)
    'oundhertobeconsist.org',
    'track.junbonet.com',
    'junbonet.com',
    'vnm.mojimobi.com',
    'mojimobi.com',
    'citimob.com',

    // Spam redirect domains
    'clk.magikmobile.com',
    'mobipush.com',
    'mobistein.com',
    'admobix.com',
    'mobusi.com',
    'mobhog.com',
    'mobile-tracking.com',
    'mobfox.com',
    'mobclick.net',
  ];

  static const List<String> _whitelistDomains = [
    // Video streaming CDNs
    'googlevideo.com',
    'youtube.com',
    '*.googlevideo.com',
'youtubei.googleapis.com',
    'vimeo.com',
    'vimeocdn.com',
    'dailymotion.com',
    'dmcdn.net',
    'twitch.tv',
    'x.com',
    'ttvnw.net',
    'play.google.com',

    // Popular CDNs
    'cloudflare.com',
    'cdnjs.cloudflare.com',
    'unpkg.com',
    'jsdelivr.net',
    'googleapis.com',
    'gstatic.com',
    'akamaized.net',
    'fastly.net',

    // Social media (nếu cần embed)
    'facebook.com',
    'fbcdn.net',
    'twitter.com',
    'twimg.com',
    'instagram.com',

    // Payment gateways
    'stripe.com',
    'paypal.com',
    'vnpay.vn',
    'momo.vn',
    'zalopay.vn',
  ];

  static final List<RegExp> _adPatterns = [
    RegExp(r'/ad[sx]?/', caseSensitive: false),
    RegExp(r'/banner', caseSensitive: false),
    RegExp(r'/popup', caseSensitive: false),
    RegExp(r'/sponsored', caseSensitive: false),
    RegExp(r'\.ad\.', caseSensitive: false),
    RegExp(r'advert', caseSensitive: false),
    RegExp(r'clicktrack', caseSensitive: false),
    RegExp(r'/track/', caseSensitive: false),
    RegExp(r'affiliate', caseSensitive: false),
    RegExp(r'/promo/', caseSensitive: false),

    // 🔥 Redirect/Tracking patterns
    RegExp(r'track\.', caseSensitive: false),
    RegExp(r'/redirect', caseSensitive: false),
    RegExp(r'/redir', caseSensitive: false),
    RegExp(r'r=', caseSensitive: false),
    RegExp(r'referrer=', caseSensitive: false),
    RegExp(r'clickid=', caseSensitive: false),
    RegExp(r'pubid=', caseSensitive: false),
    RegExp(r'affl=', caseSensitive: false),
    RegExp(r'campaign_id=', caseSensitive: false),
    RegExp(r'/download_blue/', caseSensitive: false),
    RegExp(r'/megacloud', caseSensitive: false),
  ];

  static String _currentDomain = '';

  static void setCurrentDomain(String domain) {
    if (domain.isNotEmpty) {
      try {
        _currentDomain = Uri.parse(domain).host.toLowerCase();
        print('📍 [WHITELIST-DYNAMIC] Current domain: $_currentDomain');
      } catch (e) {
        _currentDomain = '';
      }
    }
  }

  static bool _isWhitelisted(String url) {
    final lower = url.toLowerCase();

    if (_whitelistDomains.any((domain) => lower.contains(domain))) {
      return true;
    }

    if (_currentDomain.isNotEmpty && lower.contains(_currentDomain)) {
      return true;
    }

    if (_customWhitelist.any((d) => lower.contains(d))) {
      return true;
    }

    return false;
  }

  static bool _matchesAdPattern(String url) {
    return _adPatterns.any((pattern) => pattern.hasMatch(url));
  }

  static bool _shouldBlock(String url) {
    final lower = url.toLowerCase();

    if (_hardBlockedDomains.any((d) => lower.contains(d))) {
      return true;
    }

    if (_matchesAdPattern(lower)) {
      return true;
    }

    return ContentBlockerService.shouldBlockUrl(lower);
  }

  static WebResourceResponse? interceptRequest(WebResourceRequest req) {
    final url = req.url.toString();
    final lower = url.toLowerCase();

    if (_isWhitelisted(lower)) {
      return null;
    }

    if (lower.contains('.mp4') ||
        lower.contains('.m3u8') ||
        lower.contains('.mpd') ||
        lower.contains('.webm') ||
        lower.contains('manifest') ||
        lower.contains('googlevideo.com')) {
      return null;
    }

    if (_shouldBlock(lower)) {
      print("🛑 [BLOCK-RES] $url");
      return _emptyResponse();
    }

    return null;
  }

  static NavigationActionPolicy shouldOverrideUrlLoading(
      InAppWebViewController controller,
      NavigationAction action,
  ) {
    final url = action.request.url.toString();
    final lower = url.toLowerCase();
    final isMainFrame = action.isForMainFrame ?? false;

    // 1. WHITELIST - Always allow
    if (_isWhitelisted(lower)) {
      return NavigationActionPolicy.ALLOW;
    }

    // 2. Block browser open
    if (_externalSchemes.any((s) => lower.startsWith(s))) {
      print("🚫 [BLOCK-BROWSER] $url");
      return NavigationActionPolicy.CANCEL;
    }

    if (_shouldBlock(lower)) {
      final isUserClick = _isUserGesture(action);

      if (!isUserClick) {
        print("🔥 [KILL-NAV-AUTO] $url (auto redirect)");
        controller.stopLoading();
        return NavigationActionPolicy.CANCEL;
      } else {
        print("🔥 [KILL-NAV-CLICK] $url (user clicked but AD)");
        controller.stopLoading();
        return NavigationActionPolicy.CANCEL;
      }
    }

    if (isAggressiveSite(lower) && !isMainFrame) {
      final bool isUserClick = _isUserGesture(action);
      if (!isUserClick) {
        print("⚠️ [AGGRESSIVE-BLOCK] $url (iframe redirect)");
        return NavigationActionPolicy.CANCEL;
      }
    }
    final scheme = _getScheme(lower);
    if (scheme != null && !_safeSchemes.contains(scheme)) {
      print("🚫 [BLOCK-SCHEME] $scheme → $url");
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  static Future<bool> handleCreateWindow(
      InAppWebViewController controller,
      CreateWindowAction createWindowAction,
  ) async {
    final url = createWindowAction.request.url?.toString() ?? '';
    final lower = url.toLowerCase();

    print("🚨 [POPUP-ATTEMPT] $url");

    if (_isWhitelisted(lower)) {
      print("✅ [POPUP-ALLOWED] Whitelisted");
      return true;
    }

    if (_shouldBlock(lower)) {
      print("🔥 [POPUP-KILLED] Ad detected");
      return false;
    }

    if (url.isEmpty || lower.startsWith('javascript:') || lower.startsWith('about:blank')) {
      print("🔥 [POPUP-KILLED] Empty/JS popup");
      return false;
    }

    print("🚫 [POPUP-BLOCKED] Default deny");
    return false;
  }

  static void handleLoadStart(
      InAppWebViewController controller,
      WebUri? url,
  ) {
    if (url == null) return;
    final s = url.toString();
    final lower = s.toLowerCase();

    if (_isWhitelisted(lower)) return;

    if (lower.startsWith("intent://") || lower.startsWith("market://")) {
      controller.stopLoading();
      print("🔥 [KILL-INTENT] $s");
      return;
    }

    // Kill blocked URLs
    if (_shouldBlock(lower)) {
      controller.stopLoading();
      print("🔥 [LOAD-KILLED] $s");
    }
  }

  static Future<void> injectAntiPopupJS(InAppWebViewController controller) async {
    // Get base script from ContentBlockerService
    final baseScript = ContentBlockerService.getBlockingScript();

    // Extra protection
    const extraScript = '''
      (function() {
        // Prevent alert spam
        let alertCount = 0;
        const originalAlert = window.alert;
        window.alert = function(msg) {
          alertCount++;
          if (alertCount > 2) {
            console.log('[BLOCKED] Alert spam');
            return;
          }
          originalAlert.call(window, msg);
        };

        // Block confirm spam
        window.confirm = function() {
          console.log('[BLOCKED] Confirm spam');
          return false;
        };

        console.log('[Interceptor] Extra protection active');
      })();
    ''';

// YouTube Ad Blocker Script - Enhanced Version
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

    try {
      await controller.evaluateJavascript(source: youtubeAdScript);
      await controller.evaluateJavascript(source: baseScript);
      await controller.evaluateJavascript(source: extraScript);
    } catch (e) {
      print("⚠️ Failed to inject anti-popup JS: $e");
    }
  }

  static WebResourceResponse _emptyResponse() {
    return WebResourceResponse(
      contentType: 'text/plain',
      contentEncoding: 'utf-8',
      data: Uint8List(0),
    );
  }

  static bool _isUserGesture(NavigationAction action) {
    if (action.hasGesture != null) return action.hasGesture!;
    if (action.navigationType != null) {
      return action.navigationType == NavigationType.LINK_ACTIVATED;
    }
    return false;
  }

  static String? _getScheme(String url) {
    try {
      return Uri.parse(url).scheme;
    } catch (_) {
      return null;
    }
  }

  static bool isAggressiveSite(String url) {
    final l = url.toLowerCase();
    return _aggressiveSites.any((e) => l.contains(e));
  }

  static final Set<String> _customWhitelist = {};

  static void addToWhitelist(String domain) {
    _customWhitelist.add(domain.toLowerCase());
    print("✅ Added to whitelist: $domain");
  }

  static void removeFromWhitelist(String domain) {
    _customWhitelist.remove(domain.toLowerCase());
    print("❌ Removed from whitelist: $domain");
  }

  static void clearCustomWhitelist() {
    _customWhitelist.clear();
    print("🗑️ Custom whitelist cleared");
  }

  static bool isInCustomWhitelist(String url) {
    final lower = url.toLowerCase();
    return _customWhitelist.any((domain) => lower.contains(domain));
  }

  static Future<AjaxRequest?> shouldInterceptAjaxRequest(
    AjaxRequest request,
  ) async {
    final url = request.url.toString();
    final lower = url.toLowerCase();

    if (_isWhitelisted(lower)) {
      return null;
    }

    if (_shouldBlock(lower)) {
      print("🛑 [BLOCK-AJAX] $url");
      request.action = AjaxRequestAction.ABORT;
      return request;
    }

    if (_isAnalyticsRequest(lower)) {
      print("🛑 [BLOCK-ANALYTICS] $url");
      request.action = AjaxRequestAction.ABORT;
      return request;
    }
    return null;
  }

  static Future<FetchRequest?> shouldInterceptFetchRequest(
    FetchRequest request,
  ) async {
    final url = request.url.toString();
    final lower = url.toLowerCase();

    // Skip blocking cho YouTube domain
    if (
        lower.contains('youtube.com') ||
        lower.contains('googlevideo.com') ||
        lower.contains('youtubei.googleapis.com') ||
        lower.contains('ggpht.com') ||
        lower.contains('ytimg.com')) {
      return request;
    }

    if (_shouldBlock(lower)) {
      print("🛑 [BLOCK-FETCH] $url");
      // Abort request để chặn
      request.action = FetchRequestAction.ABORT;
      return request;
    }

    if (_isAnalyticsRequest(lower)) {
      print("🛑 [BLOCK-ANALYTICS-FETCH] $url");
      request.action = FetchRequestAction.ABORT;
      return request;
    }

    return null;
  }

  static bool _isAnalyticsRequest(String url) {
    final lower = url.toLowerCase();

    final analyticsKeywords = [
      '/analytics', '/track', '/tracking', '/telemetry',
      '/collect', '/beacon', '/pixel', '/metrics',
      '/stats', '/monitor',
      'google-analytics.com', 'googletagmanager.com',
      'googlesyndication.com', 'doubleclick.net',
      'facebook.com/tr/', 'fbq', 'fbc',
      'hotjar.com', 'segment.io', 'mixpanel.com',
      'amplitude.com', 'fullstory.com', 'clarity.ms',
      'mouseflow.com', 'inspectlet.com', 'heap.io',
    ];

    for (final keyword in analyticsKeywords) {
      if (lower.contains(keyword)) {
        return true;
      }
    }

    return false;
  }
}
