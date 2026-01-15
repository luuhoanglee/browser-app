import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class IOSContentBlockerService {
  IOSContentBlockerService._();

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
}