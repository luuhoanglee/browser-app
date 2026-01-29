// import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class IOSContentBlockerService {
  IOSContentBlockerService._();

  static const List<String> criticalBlockedDomains = [
    'acscdn.com',
    'acsbcdn.com',
    'acs86.com',
    'flinchrecyclingrouting.com',
    'astronautlividlyreformer.com',
    'notificationpushmonetization.com',
    'pushmonetization.com',

    'popads.net',
    'popcash.net',
    'propellerads.com',
    'adsterra.com',
    'exoclick.com',
    'popunderjs.com',

    'oundhertobeconsist.org',
    'track.junbonet.com',
    'junbonet.com',
    'vnm.mojimobi.com',
    'clk.magikmobile.com',

    'coinhive.com',
    'coin-hive.com',
    'jsecoin.com',
    'cryptoloot.pro',
  ];

  static const List<String> secondaryBlockedDomains = [
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'taboola.com',
    'outbrain.com',
    'revcontent.com',
    'pubfuture-ad.com',
    'gotrackier.com',
    'oclaserver.com',
    'appmontize.com',
  ];

  static const String cssSelectors = '''
    .ad, .ads, .advert, .banner, .popup, .popunder,
    .qc, .quangcao, .sponsor, .promo,
    iframe[src*="ads"], iframe[src*="doubleclick"],
    [class*="ad-"], [id*="ad-"], [class*="qc-"], [id*="qc-"]
  ''';

  static List<ContentBlocker> getContentBlockers({
    bool enableAggressiveBlocking = true,
  }) {
    final List<ContentBlocker> blockers = [];

    blockers.add(
      ContentBlocker(
        trigger: ContentBlockerTrigger(urlFilter: '.*'),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.CSS_DISPLAY_NONE,
          selector: cssSelectors.trim(),
        ),
      ),
    );

    _addDomainBlockers(blockers, criticalBlockedDomains, "Critical");

    if (enableAggressiveBlocking) {
      _addDomainBlockers(blockers, secondaryBlockedDomains, "Secondary");
    }

    blockers.add(
      ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: '.*(pop|push|redirect|track|click|ads).*',
          loadType: [ContentBlockerTriggerLoadType.THIRD_PARTY],
          resourceType: [
            ContentBlockerTriggerResourceType.DOCUMENT,
            ContentBlockerTriggerResourceType.RAW,
          ],
        ),
        action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
      ),
    );
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
            loadType: [ContentBlockerTriggerLoadType.THIRD_PARTY],
            resourceType: [
              ContentBlockerTriggerResourceType.SCRIPT,
              ContentBlockerTriggerResourceType.IMAGE,
              ContentBlockerTriggerResourceType.STYLE_SHEET,
              ContentBlockerTriggerResourceType.RAW,
              ContentBlockerTriggerResourceType.MEDIA,
              ContentBlockerTriggerResourceType.DOCUMENT,
            ],
          ),
          action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
        ),
      );
    }
  }
}
