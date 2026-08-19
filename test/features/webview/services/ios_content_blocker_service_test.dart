import 'package:browser_app/features/webview/services/ios_content_blocker_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not apply the aggressive third-party rule on TikTok pages', () {
    final blockers = IOSContentBlockerService.getContentBlockers();
    final aggressiveRule = blockers.firstWhere(
      (blocker) => blocker.trigger.urlFilter.contains('redirect|track'),
    );

    expect(
      aggressiveRule.trigger.unlessTopUrl,
      containsAll(<String>['https://tiktok.com/*', 'https://*.tiktok.com/*']),
    );
  });
}
