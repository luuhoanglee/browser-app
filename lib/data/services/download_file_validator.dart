class DownloadIntegrityException implements Exception {
  final int actualBytes;
  final int? expectedBytes;

  const DownloadIntegrityException({
    required this.actualBytes,
    this.expectedBytes,
  });

  @override
  String toString() {
    return 'Downloaded file failed integrity check '
        '(expected ${expectedBytes ?? 'non-empty'}, got $actualBytes bytes).';
  }
}

class DownloadFileValidator {
  const DownloadFileValidator._();

  static bool isHlsUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.m3u8');
  }

  static void verifyLength({required int actual, int? expected}) {
    if (actual <= 0 ||
        (expected != null && expected > 0 && actual != expected)) {
      throw DownloadIntegrityException(
        actualBytes: actual,
        expectedBytes: expected,
      );
    }
  }
}
