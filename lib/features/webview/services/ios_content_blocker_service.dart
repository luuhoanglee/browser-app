import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class IOSContentBlockerService {
  IOSContentBlockerService._();

  static String? _cachedRules;
  static Future<void>? _initFuture;

  static const List<String> blockedAdDomains = [
    // Google Ads
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'adservice.google.com',

    // Common ad networks
    'mgid.com',
    'adsterra.com',
    'popads.net',
    'popcash.net',
    'propellerads.com',
    'hilltopads.net',
    'exoclick.com',
    'trafficjunky.net',
    'adnxs.com',
    'advertising.com',
    'juicyads.com',

    // Native ad networks
    'outbrain.com',
    'taboola.com',
    'revcontent.com',
    'criteo.com',

    // ACS Ad Network - THE MAIN CULPRIT!
    'acscdn.com',
    'acsbcdn.com',
    'acs86.com',
    'flinchrecyclingrouting.com',
    'astronautlividlyreformer.com',
    'notificationpushmonetization.com',
    'pushmonetization.com',

    // Vietnamese ad networks
    'admicro.vn',
    'adtrue.vn',
    'adpia.vn',
    'novanet.vn',
    'ambientdsp.com',
    'vcmedia.vn',
    'adinplay.com',
    'pubfuture-ad.com',
    'adsplay.net',
    'sohoad.vn',
    'adnetwork.vn',

    // Analytics/Trackers
    'hotjar.com',
    'mouseflow.com',
    'inspectlet.com',
    'segment.io',
    'mixpanel.com',
    'sfaobvfic.in',

    // Crypto miners
    'coinhive.com',
    'coin-hive.com',
    'jsecoin.com',
    'cryptoloot.pro',

    // Redirect spam
    'popunderjs.com',
  ];

  // ============================================================
  // WHITELIST DOMAINS
  // ============================================================

  static const List<String> whitelistDomains = [
    // Google / YouTube
    'youtube.com',
    'youtu.be',
    'googlevideo.com',
    'gstatic.com',
    'googleapis.com',
    'googleusercontent.com',
    'ytimg.com',
    'yt3.ggpht.com',

    // Video CDNs
    'cloudflare.com',
    'cloudflare.net',
    'cloudflareinsights.com',
    'cloudfront.net',
    'fastly.com',
    'fastly.net',
    'akamai.com',
    'akamaihd.net',
    'akamaized.net',
    'jwplayer.com',
    'jwpcdn.com',
    'vimeocdn.com',
    'vimeo.com',
    'dailymotioncdn.net',
    'dailymotion.com',
    'dmcdn.net',
    'twitch.tv',
    'ttvnw.net',

    // JS / Fonts / Images
    'cdnjs.com',
    'cdnjs.cloudflare.com',
    'jsdelivr.net',
    'unpkg.com',
    'fonts.googleapis.com',
    'fontawesome.com',
    'bootstrapcdn.com',
    'jquery.com',

    // Social media (for embed)
    'facebook.com',
    'fbcdn.net',
    'twitter.com',
    'twimg.com',
    'instagram.com',

    // VN
    'fshare.vn',
    'cdn.fshare.vn',
    'drive.google.com',

    // Payment gateways
    'stripe.com',
    'paypal.com',
    'vnpay.vn',
    'momo.vn',
    'zalopay.vn',
  ];

  static const String cssSelectors = '''
    .ad, .ads, .advert, .banner, .popup, .popunder,
    .qc, .quangcao, .sponsor, .promo,
    iframe[src*="ads"], iframe[src*="doubleclick"],
    [class*="ad-"], [id*="ad-"], [class*="qc-"], [id*="qc-"]
  ''';

  /// Initialize service by loading rules from asset file
  static Future<void> initialize() async {
    _initFuture ??= _loadFromAsset();
    return _initFuture;
  }

  /// Load content blocker rules from assets/blockerList.json
  static Future<void> _loadFromAsset() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/blockerList.json');

      // Validate JSON
      final dynamic json = jsonDecode(jsonString);
      if (json is List && json.isNotEmpty) {
        _cachedRules = jsonString;
        debugPrint('✅ [iOSContentBlocker] Loaded ${json.length} rules from asset');
      } else {
        debugPrint('⚠️ [iOSContentBlocker] Invalid JSON format, using fallback');
        _cachedRules = _generateFallbackRules();
      }
    } catch (e) {
      debugPrint('⚠️ [iOSContentBlocker] Failed to load asset: $e');
      _cachedRules = _generateFallbackRules();
    }
  }

  /// Generate fallback rules if asset loading fails
  static String _generateFallbackRules() {
    final List<Map<String, dynamic>> rules = [];

    // Domain-based blocking
    for (final domain in blockedAdDomains) {
      rules.add({
        'trigger': {
          'url-filter': '.*$domain.*',
          'url-filter-is-case-sensitive': false,
        },
        'action': {'type': 'block'},
      });
    }

    // CSS hiding
    rules.add({
      'trigger': {'url-filter': '.*'},
      'action': {
        'type': 'css-display-none',
        'selector': cssSelectors,
      },
    });

    debugPrint('✅ [iOSContentBlocker] Generated ${rules.length} fallback rules');
    return jsonEncode(rules);
  }


  static Future<String> getContentBlockerRules() async {
    // Load from asset if not cached
    if (_cachedRules == null) {
      await initialize();
    }

    return _cachedRules ?? '[]';
  }

  static List<ContentBlocker> getContentBlockers() {
    final List<ContentBlocker> blockers = [];

    // 1. Domain-based blocking
    for (final domain in blockedAdDomains) {
      blockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: '.*$domain.*',
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          ),
        ),
      );
    }

    // 2. CSS hiding
    blockers.add(
      ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: '.*',
        ),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.CSS_DISPLAY_NONE,
          selector: cssSelectors,
        ),
      ),
    );

    debugPrint('✅ [iOSContentBlocker] Created ${blockers.length} blockers');
    return blockers;
  }

  static String getAntiPopupScript() {
    return '''
(function() {
  const blocked = [${blockedAdDomains.map((e) => "'$e'").join(",")}];
  const whitelist = [${whitelistDomains.map((e) => "'$e'").join(",")}];

  function isBlocked(url) {
    url = (url || "").toLowerCase();
    for (const w of whitelist) if (url.includes(w)) return false;
    for (const b of blocked) if (url.includes(b)) return true;
    return false;
  }

  // Block window.open
  const originalOpen = window.open;
  window.open = function(u){
    if (isBlocked(u)) {
      console.log('[BLOCKED] window.open:', u);
      return null;
    }
    return originalOpen.apply(this, arguments);
  };

  // Block redirects
  const assign = location.assign;
  location.assign = function(u){ if (!isBlocked(u)) assign.call(location,u); };

  const replace = location.replace;
  location.replace = function(u){ if (!isBlocked(u)) replace.call(location,u); };

  // Kill ad iframes
  new MutationObserver(() => {
    document.querySelectorAll("iframe").forEach(f=>{
      if(isBlocked(f.src)) {
        console.log('[KILLED] Ad iframe:', f.src);
        f.remove();
      }
    });
  }).observe(document, {subtree:true, childList:true});

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

  console.log('[iOSContentBlocker] Protection active');
})();
''';
  }

  /// Inject anti-popup JavaScript into WebView
  static Future<void> injectAntiPopupJS(InAppWebViewController controller) async {
    try {
      await controller.evaluateJavascript(source: getAntiPopupScript());
      debugPrint('✅ [iOSContentBlocker] Anti-popup JS injected');
    } catch (e) {
      debugPrint('⚠️ [iOSContentBlocker] Failed to inject JS: $e');
    }
  }

  // 
  /// Check if URL should be blocked
  static bool shouldBlockUrl(String url) {
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();

    // Check whitelist
    for (final domain in whitelistDomains) {
      if (lower.contains(domain)) return false;
    }

    // Check blocked domains
    for (final domain in blockedAdDomains) {
      if (lower.contains(domain)) {
        debugPrint('🚫 [iOSContentBlocker] Blocked: $url');
        return true;
      }
    }

    // Check patterns
    final adPatterns = [
      RegExp(r'/ad[sx]?/', caseSensitive: false),
      RegExp(r'/banner', caseSensitive: false),
      RegExp(r'/popup', caseSensitive: false),
      RegExp(r'/sponsored', caseSensitive: false),
      RegExp(r'\.ad\.', caseSensitive: false),
      RegExp(r'advert', caseSensitive: false),
      RegExp(r'clicktrack', caseSensitive: false),
      RegExp(r'/track/', caseSensitive: false),
    ];

    for (final pattern in adPatterns) {
      if (pattern.hasMatch(lower)) {
        debugPrint('🚫 [iOSContentBlocker] Pattern blocked: $url');
        return true;
      }
    }

    return false;
  }

  /// Add domain to custom whitelist (runtime only)
  static final Set<String> customWhitelist = {};

  static void addToWhitelist(String domain) {
    customWhitelist.add(domain.toLowerCase());
    debugPrint('✅ [iOSContentBlocker] Added to whitelist: $domain');
  }

  static void removeFromWhitelist(String domain) {
    customWhitelist.remove(domain.toLowerCase());
    debugPrint('❌ [iOSContentBlocker] Removed from whitelist: $domain');
  }

  static void clearCustomWhitelist() {
    customWhitelist.clear();
    debugPrint('🗑️ [iOSContentBlocker] Custom whitelist cleared');
  }

  static bool isInWhitelist(String url) {
    final lower = url.toLowerCase();

    // Check static whitelist
    for (final domain in whitelistDomains) {
      if (lower.contains(domain)) return true;
    }

    // Check custom whitelist
    return customWhitelist.any((domain) => lower.contains(domain));
  }
}
