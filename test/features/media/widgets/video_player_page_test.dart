import 'package:browser_app/features/media/widgets/video_player_page.dart';
import 'package:browser_app/features/media/widgets/media_gallery_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('castContentTypeForUrl', () {
    test('identifies HLS streams including query parameters', () {
      expect(
        castContentTypeForUrl(
          'https://cdn.example.com/master.m3u8?token=secret',
        ),
        'application/x-mpegURL',
      );
    });

    test('identifies WebM and defaults unknown video URLs to MP4', () {
      expect(
        castContentTypeForUrl('https://cdn.example.com/video.webm'),
        'video/webm',
      );
      expect(
        castContentTypeForUrl('https://cdn.example.com/play?id=42'),
        'video/mp4',
      );
    });
  });

  group('parsePlayingVideoIndexes', () {
    test('parses the JSON returned by WebView JavaScript', () {
      expect(parsePlayingVideoIndexes('[0,2]'), [0, 2]);
    });

    test('accepts decoded lists and rejects invalid results', () {
      expect(parsePlayingVideoIndexes(<dynamic>[1, 3]), [1, 3]);
      expect(parsePlayingVideoIndexes('not-json'), isEmpty);
    });
  });
}
