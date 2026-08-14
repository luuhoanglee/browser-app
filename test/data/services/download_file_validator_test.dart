import 'package:browser_app/data/services/download_file_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DownloadFileValidator', () {
    test('detects HLS URLs even when they contain a query', () {
      expect(
        DownloadFileValidator.isHlsUrl(
          'https://example.com/video/master.m3u8?token=temporary',
        ),
        isTrue,
      );
      expect(
        DownloadFileValidator.isHlsUrl('https://example.com/video/movie.mp4'),
        isFalse,
      );
    });

    test('rejects empty and truncated downloads', () {
      expect(
        () => DownloadFileValidator.verifyLength(actual: 0),
        throwsA(isA<DownloadIntegrityException>()),
      );
      expect(
        () => DownloadFileValidator.verifyLength(actual: 50, expected: 100),
        throwsA(isA<DownloadIntegrityException>()),
      );
    });

    test('accepts matching and non-empty downloads with unknown length', () {
      expect(
        () => DownloadFileValidator.verifyLength(actual: 100, expected: 100),
        returnsNormally,
      );
      expect(
        () => DownloadFileValidator.verifyLength(actual: 100),
        returnsNormally,
      );
    });
  });
}
