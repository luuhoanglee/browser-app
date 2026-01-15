import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    show
        ContentBlocker,
        ContentBlockerAction,
        ContentBlockerActionType,
        ContentBlockerTrigger,
        ContentBlockerTriggerLoadType,
        ContentBlockerTriggerResourceType;

class IOSContentBlockerService {
  IOSContentBlockerService._();

  static const List<String> adPaths = [
    '/ads',
    '/ad/',
    '/advert',
    '/popup',
    '/popunder',
    '/banner',
    '/tracking',
    '/analytics',
    '/pixel',
    '/beacon',
    '/telemetry',
    '/click',
    '/promo',
    '/sponsored',
  ];

  static const List<String> safePaths = [
    '/api',
    '/cdn-cgi',
    '/rum',
    '/images',
    '/video',
    '/stream',
    '/hls',
    '/dash',
    '/manifest',
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

  static const List<String> criticalBlockedDomains = [
    // ACS Ad Network - Main culprit
    'acscdn.com',
    'acsbcdn.com',
    'acs86.com',
    'flinchrecyclingrouting.com',
    'astronautlividlyreformer.com',
    'notificationpushmonetization.com',
    'pushmonetization.com',

    // Aggressive popups/redirects
    'popads.net',
    'popcash.net',
    'propellerads.com',
    'adsterra.com',
    'exoclick.com',
    'popunderjs.com',

    // Tracking redirects (from your logs)
    'oundhertobeconsist.org',
    'track.junbonet.com',
    'junbonet.com',
    'vnm.mojimobi.com',
    'clk.magikmobile.com',

    // Crypto miners
    'coinhive.com',
    'coin-hive.com',
    'jsecoin.com',
    'cryptoloot.pro',
  ];

  // Optional: Block less aggressive ads
  static const List<String> secondaryBlockedDomains = [
    'knowledgeable-let.com',
    'gotrackier.com',
    'appmontize.com',
    'oclaserver.com',
    'pubfuture-ad.com',
    'al5sm.com',
    '255md.com',
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'taboola.com',
    'outbrain.com',
    'revcontent.com',
  ];

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

    // Social media
    'facebook.com',
    'fbcdn.net',
    'twitter.com',
    'twimg.com',
    'instagram.com',

    // Vietnam
    'fshare.vn',
    'cdn.fshare.vn',
    'drive.google.com',

    // Payment
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

  static List<ContentBlocker> getContentBlockers({
    bool enableAggressiveBlocking = false,
  }) {
    final List<ContentBlocker> blockers = [];

    blockers.add(
      ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: '.*',
        ),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.CSS_DISPLAY_NONE,
          selector: cssSelectors.trim(),
        ),
      ),
    );

    _addDomainBlockers(
      blockers,
      criticalBlockedDomains,
      'Critical',
    );

    if (enableAggressiveBlocking) {
      _addDomainBlockers(
        blockers,
        secondaryBlockedDomains,
        'Secondary',
      );
    }

    if (kDebugMode) {
      print('✅ [iOS ContentBlocker] Initialized successfully');
      print('   - CSS blocker: 1');
      print('   - Critical domains: ${criticalBlockedDomains.length}');
      if (enableAggressiveBlocking) {
        print('   - Secondary domains: ${secondaryBlockedDomains.length}');
      }
      print('   - Total blockers: ${blockers.length}');
    }

    return blockers;
  }

  static void _addDomainBlockers(
    List<ContentBlocker> blockers,
    List<String> domains,
    String category,
  ) {
    const batchSize = 10;

    for (int i = 0; i < domains.length; i += batchSize) {
      final batch = domains.skip(i).take(batchSize).toList();
      final pattern = batch.map((d) => d.replaceAll('.', r'\.')).join('|');

      blockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: '.*($pattern).*',

            loadType: [
              ContentBlockerTriggerLoadType.THIRD_PARTY,
            ],

            resourceType: [
              ContentBlockerTriggerResourceType.SCRIPT,
              ContentBlockerTriggerResourceType.IMAGE,
              ContentBlockerTriggerResourceType.STYLE_SHEET,
            ],
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          ),
        ),
      );
    }

    if (kDebugMode) {
      final numBatches = (domains.length / batchSize).ceil();
      print('   - $category: ${domains.length} domains in $numBatches batches');
    }
  }

  /// Check if URL should be blocked
  static bool shouldBlockUrl(String url) {
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();

    // Skip YouTube
    if (_isYouTubeUrl(lower)) return false;

    // Check whitelist first
    if (_isWhitelisted(lower)) return false;

    // Check blocked domains
    final allBlockedDomains = [
      ...criticalBlockedDomains,
      ...secondaryBlockedDomains,
    ];

    for (final domain in allBlockedDomains) {
      if (lower.contains(domain)) {
        debugPrint('🚫 [iOSContentBlocker] Blocked domain: $url');
        return true;
      }
    }

    // Check safe paths first (skip blocking)
    if (_matchesAny(lower, safePaths)) return false;

    // Check ad paths
    if (_matchesAny(lower, adPaths)) {
      debugPrint('🚫 [iOSContentBlocker] Blocked path: $url');
      return true;
    }

    // Check ad patterns
    if (_matchesAdPattern(lower)) {
      debugPrint('🚫 [iOSContentBlocker] Blocked pattern: $url');
      return true;
    }

    return false;
  }

  /// Check if URL is in whitelist
  static bool isInWhitelist(String url) {
    return _isWhitelisted(url.toLowerCase());
  }

  /// Check if URL is a YouTube URL
  static bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('googlevideo.com') ||
        url.contains('ytimg.com') ||
        url.contains('youtubei.googleapis.com');
  }

  /// Check if URL is whitelisted
  static bool _isWhitelisted(String url) {
    return whitelistDomains.any((domain) => url.contains(domain));
  }

  /// Check if URL matches any string in list
  static bool _matchesAny(String url, List<String> list) {
    for (final s in list) {
      if (url.contains(s)) return true;
    }
    return false;
  }

  /// Check if URL matches any ad pattern
  static bool _matchesAdPattern(String url) {
    return adPatterns.any((pattern) => pattern.hasMatch(url));
  }

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

  static bool isInCustomWhitelist(String url) {
    final lower = url.toLowerCase();
    return customWhitelist.any((domain) => lower.contains(domain));
  }
}