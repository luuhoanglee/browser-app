import 'package:browser_app/features/webview/services/webview_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  group('WebViewInterceptor.isMediaRequestUrl', () {
    test('allows Jable HLS playlists hosted on mushroomtrack.com', () {
      const url =
          'https://austin-billion.mushroomtrack.com/hls/video/60903/60903.m3u8';

      expect(WebViewInterceptor.isMediaRequestUrl(url), isTrue);
    });

    test('allows Jable HLS transport stream segments', () {
      const url =
          'https://austin-billion.mushroomtrack.com/hls/video/60903/segment.ts';

      expect(WebViewInterceptor.isMediaRequestUrl(url), isTrue);
    });

    test('does not classify tracking requests as media', () {
      const url = 'https://track.example.com/click?campaign_id=123';

      expect(WebViewInterceptor.isMediaRequestUrl(url), isFalse);
    });

    test('allows HLS through resource, AJAX, and Fetch interception', () async {
      final playlistUrl = WebUri(
        'https://austin-billion.mushroomtrack.com/hls/video/60903/60903.m3u8',
      );
      final segmentUrl = WebUri(
        'https://austin-billion.mushroomtrack.com/hls/video/60903/segment.ts',
      );

      final resourceResult = WebViewInterceptor.interceptRequest(
        WebResourceRequest(url: segmentUrl),
      );
      final ajaxResult = await WebViewInterceptor.shouldInterceptAjaxRequest(
        AjaxRequest(url: playlistUrl),
      );
      final fetchRequest = FetchRequest(url: segmentUrl);
      final fetchResult = await WebViewInterceptor.shouldInterceptFetchRequest(
        fetchRequest,
      );

      expect(resourceResult, isNull);
      expect(ajaxResult, isNull);
      expect(fetchResult, same(fetchRequest));
      expect(fetchResult?.action, FetchRequestAction.PROCEED);
    });

    test('still aborts a non-media tracker AJAX request', () async {
      final request = AjaxRequest(
        url: WebUri('https://track.example.com/click?campaign_id=123'),
      );

      final result = await WebViewInterceptor.shouldInterceptAjaxRequest(
        request,
      );

      expect(result, same(request));
      expect(result?.action, AjaxRequestAction.ABORT);
    });
  });
}
