import 'dart:typed_data';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'ad_pattern_loader.dart';

class ContentBlockerService {
  ContentBlockerService._();

  static final AdPatternLoader _patternLoader = AdPatternLoader.instance;

  static const List<String> whitelistDomains = [
    // Google / YouTube
    'youtube.com', 'youtu.be', 'googlevideo.com',
    'gstatic.com', 'googleapis.com', 'googleusercontent.com',
    'ytimg.com', 'yt3.ggpht.com',

    // Video CDNs
    'cloudflare.com', 'cloudflare.net', 'cloudflareinsights.com',
    'cloudfront.net', 'fastly.com', 'fastly.net',
    'akamai.com', 'akamaihd.net', 'akamaized.net',
    'jwplayer.com', 'jwpcdn.com',
    'vimeocdn.com', 'vimeo.com', 'dailymotioncdn.net', 'dailymotion.com', 'dmcdn.net',
    'twitch.tv', 'ttvnw.net',

    // JS / Fonts / Images
    'cdnjs.com', 'cdnjs.cloudflare.com', 'jsdelivr.net', 'unpkg.com',
    'fonts.googleapis.com', 'fontawesome.com',
    'bootstrapcdn.com', 'jquery.com',

    // Social media (for embed)
    'facebook.com', 'fbcdn.net',
    'twitter.com', 'twimg.com',
    'instagram.com',

    // VN
    'fshare.vn', 'cdn.fshare.vn',
    'drive.google.com',

    // Payment gateways
    'stripe.com', 'paypal.com',
    'vnpay.vn', 'momo.vn', 'zalopay.vn',
  ];

  // ============================================================
  // HARD BLOCKED AD DOMAINS
  // ============================================================

  static const List<String> blockedAdDomains = [
    // Original
    'knowledgeable-let.com',
    'gotrackier.com',
    'appmontize.com',
    'oclaserver.com',
    'al5sm.com',
    '255md.com',

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

    // ⭐ ACS Ad Network - THE MAIN CULPRIT!
    'acscdn.com',
    'acsbcdn.com',
    'acs86.com',
    // 'oundhertobeconsist.org',
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
  // SCHEMES & SPECIAL SITES
  // ============================================================

  static const Set<String> safeSchemes = {
    'http', 'https', 'file', 'data', 'about', 'javascript', 'ws', 'wss'
  };

  static const List<String> externalSchemes = [
    'googlechrome://', 'firefox://', 'chrome://', 'edge://', 'opera://',
    'intent://', 'market://'
  ];

  static const List<String> aggressiveSites = [
    'fmovies','123movies','putlocker','gomovies','yesmovies',
    'phimmoi','anime','xmovies','hdmovies','watch','stream',
    'motphim','phim14','phim3s','bilutv','animehay','aquareader'
  ];

  static const List<String> adPaths = [
    '/ads', '/ad/', '/advert', '/popup', '/popunder',
    '/banner', '/tracking', '/analytics', '/pixel',
    '/beacon', '/telemetry', '/click', '/promo',
    '/sponsored',
  ];

  static final List<RegExp> adPatterns = [
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
  ];

  static const List<String> safePaths = [
    '/api', '/cdn-cgi', '/rum', '/images', '/video',
    '/stream', '/hls', '/dash', '/manifest'
  ];

  static final Set<String> customWhitelist = {};

  static Future<void>? _initFuture;

  static Future<void> initialize() async {
    _initFuture ??= _patternLoader.loadPatterns();
    return _initFuture;
  }

  static bool shouldBlockUrl(String url) {
  if (url.isEmpty) return false;
  final lower = url.toLowerCase();
  if (lower.contains("youtube.com") ||
    lower.contains("youtubei.googleapis.com") ||
    lower.contains("googlevideo.com") ||
    lower.contains("ytimg.com")) {
  return false;
}

  if (isWhitelisted(lower)) return false;

  if (_matchesAny(lower, blockedAdDomains)) {
    print("🚫 [AdBlock] $url");
    return true;
  }

  if (_matchesAny(lower, safePaths)) return false;

  // ❌ Disable adPaths for YouTube
  if (lower.contains("youtube.com") || lower.contains("googlevideo.com")) {
    // skip adPaths
  } else if (_matchesAny(lower, adPaths)) {
    print("🚫 [AdBlock Path] $url");
    return true;
  }

  if (_matchesAdPattern(lower)) {
    print("🚫 [AdBlock Pattern] $url");
    return true;
  }

  if (_patternLoader.isLoaded && _patternLoader.matches(lower)) {
    // skip for youtube
    if (!lower.contains("youtube.com") &&
        !lower.contains("youtubei.googleapis.com") &&
        !lower.contains("googlevideo.com")) {
      print("🚫 [AdBlock FilePattern] $url");
      return true;
    }
  }

  return false;
}


  static bool isWhitelisted(String url) {
    final lower = url.toLowerCase();

    if (_matchesAny(lower, whitelistDomains)) return true;

    if (customWhitelist.any((d) => lower.contains(d))) return true;

    return false;
  }

  static bool _matchesAny(String url, List<String> list) {
    for (final s in list) {
      if (url.contains(s)) return true;
    }
    return false;
  }

  static bool _matchesAdPattern(String url) {
    return adPatterns.any((pattern) => pattern.hasMatch(url));
  }

  static WebResourceResponse? interceptRequest(WebResourceRequest req) {
    final url = req.url.toString();
    final lower = url.toLowerCase();

    if (isWhitelisted(lower)) {
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

    if (shouldBlockUrl(lower)) {
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

    if (isWhitelisted(lower)) {
      return NavigationActionPolicy.ALLOW;
    }

    if (externalSchemes.any((s) => lower.startsWith(s))) {
      print("🚫 [BLOCK-BROWSER] $url");
      return NavigationActionPolicy.CANCEL;
    }

      if (shouldBlockUrl(lower)) {
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

    // 4. Extra protection for aggressive sites
    if (isAggressiveSite(lower)) {
      final bool isUserClick = _isUserGesture(action);
      if (!isUserClick) {
        final isMainFrame = action.isForMainFrame ?? false;
        if (!isMainFrame) {
          print("⚠️ [AGGRESSIVE-BLOCK] $url");
          return NavigationActionPolicy.CANCEL;
        }
      }
    }

    final scheme = _getScheme(lower);
    if (scheme != null && !safeSchemes.contains(scheme)) {
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

    if (isWhitelisted(lower)) {
      print("✅ [POPUP-ALLOWED] Whitelisted");
      return true;
    }
    if (shouldBlockUrl(lower)) {
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

    if (isWhitelisted(lower)) return;

    if (lower.startsWith("intent://") || lower.startsWith("market://")) {
      controller.stopLoading();
      print("🔥 [KILL-INTENT] $s");
      return;
    }

    if (shouldBlockUrl(lower)) {
      controller.stopLoading();
      print("🔥 [LOAD-KILLED] $s");
    }
  }

  static Future<void> injectAntiPopupJS(InAppWebViewController controller) async {
    final baseScript = getBlockingScript();

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

        console.log('[ContentBlocker] Extra protection active');
      })();
    ''';

    try {
      await controller.evaluateJavascript(source: baseScript);
      await controller.evaluateJavascript(source: extraScript);
      print("✅ Anti-popup JS injected");
    } catch (e) {
      print("⚠️ Failed to inject anti-popup JS: $e");
    }
  }

  static List<ContentBlocker> createAdBlockers() {
    return [
      for (final domain in blockedAdDomains)
        ContentBlocker(
          trigger: ContentBlockerTrigger(urlFilter: ".*$domain.*"),
          action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
        ),
      ContentBlocker(
        trigger: ContentBlockerTrigger(urlFilter: ".*"),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.CSS_DISPLAY_NONE,
          selector: _cssSelectors,
        ),
      ),
    ];
  }

  static String getBlockingScript() {
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

  console.log('[ContentBlocker] Protection active');
})();
''';
  }

  static const String _cssSelectors = '''
  .ad, .ads, .advert, .banner, .popup, .popunder,
  .qc, .quangcao, .sponsor, .promo,
  iframe[src*="ads"], iframe[src*="doubleclick"],
  [class*="ad-"], [id*="ad-"], [class*="qc-"], [id*="qc-"]
  ''';

  static void addToWhitelist(String domain) {
    customWhitelist.add(domain.toLowerCase());
    print("✅ Added to whitelist: $domain");
  }

  static void removeFromWhitelist(String domain) {
    customWhitelist.remove(domain.toLowerCase());
    print("❌ Removed from whitelist: $domain");
  }

  static void clearCustomWhitelist() {
    customWhitelist.clear();
    print("🗑️ Custom whitelist cleared");
  }

  static bool isInCustomWhitelist(String url) {
    final lower = url.toLowerCase();
    return customWhitelist.any((domain) => lower.contains(domain));
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
    return aggressiveSites.any((e) => l.contains(e));
  }
}
