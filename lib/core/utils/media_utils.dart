import 'package:browser_app/core/enum/media_type.dart';

/// Media URL detection utilities
class MediaUtils {
  MediaUtils._();

  // Image extensions
  static const imageExts = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg', '.ico',
  ];

  // Video extensions
  static const videoExts = [
    '.mp4', '.webm', '.ogg', '.mov', '.avi', '.mkv', '.m4v', '.flv',
    '.wmv', '.3gp', '.m3u8', '.ts',
  ];

  // Audio extensions
  static const audioExts = [
    '.mp3', '.wav', '.aac', '.flac', '.m4a', '.wma', '.opus', '.ogg',
  ];

  // Domains to skip (login pages, ads, tracking, etc.)
  static const skippedDomains = [
    'accounts.google.com',
    'www.facebook.com',
    'adexchangeclear.com',
    'google.com',
    'facebook.com',
    // 'youtube.com',
    'doubleclick.net',
    'googlesyndication.com',
  ];

  // Skip URLs with these patterns
  static const skippedPatterns = [
    'servicelogin',
    'login.php',
    'adexchange',
    'script/suurl',
    '/suurl',
    'favicon.ico',
  ];

  /// Check if URL should be skipped
  static bool shouldSkip(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return true;

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final urlLower = url.toLowerCase();

    // Skip by domain
    for (final domain in skippedDomains) {
      if (host == domain || host.endsWith('.$domain')) {
        return true;
      }
    }

    // Skip by pattern
    for (final pattern in skippedPatterns) {
      if (urlLower.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Check if URL is an image resource
  static bool isImage(String url) {
    if (shouldSkip(url)) return false;
    return _checkMediaType(url, imageExts);
  }

  /// Check if URL is a video resource
  static bool isVideo(String url) {
    if (shouldSkip(url)) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final urlLower = url.toLowerCase();

    // Check extensions (must be in path, not just in query)
    if (_checkMediaTypeStrict(url, videoExts)) return true;

    // Only check mime type for whitelisted domains
    if (urlLower.contains('video/')) return false; // Too broad, skip

    // Check MIME type patterns in query string
    if (urlLower.contains('format=video') ||
        urlLower.contains('type=video') ||
        urlLower.contains('mime=video') ||
        urlLower.contains('contenttype=video')) {
      // Only accept if it's from a known streaming domain
      final host = uri.host.toLowerCase();
      if (!_isStreamingDomain(host)) {
        return false;
      }
      return true;
    }

    return false;
  }

  /// Check if URL is an audio resource
  static bool isAudio(String url) {
    if (shouldSkip(url)) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final urlLower = url.toLowerCase();

    // Check extensions (must be in path, not just in query)
    if (_checkMediaTypeStrict(url, audioExts)) return true;

    // Check mime type in URL
    if (urlLower.contains('audio/')) {
      final host = uri.host.toLowerCase();
      if (!_isStreamingDomain(host)) {
        return false;
      }
      return true;
    }

    // Check for music streaming CDN domains (ZingMP3, etc.)
    if (uri.host.contains('zmdcdn.me') || uri.host.contains('zadn.vn')) {
      if (urlLower.contains('?authen=') || urlLower.contains('&authen=')) {
        return true;
      }
    }

    // Check common audio MIME type patterns in query string
    if (urlLower.contains('format=audio') ||
        urlLower.contains('type=audio') ||
        urlLower.contains('mime=audio') ||
        urlLower.contains('contenttype=audio')) {
      final host = uri.host.toLowerCase();
      if (!_isStreamingDomain(host)) {
        return false;
      }
      return true;
    }

    return false;
  }

  /// Check if host is a known streaming/media domain
  static bool _isStreamingDomain(String host) {
    final streamingDomains = [
      'zmdcdn.me',
      'zadn.vn',
      'vidsrc.me',
      'tinyzone.org',
      'tmdb.org',
      'icdn.my.id',
    ];

    for (final domain in streamingDomains) {
      if (host == domain || host.endsWith('.$domain')) {
        return true;
      }
    }
    return false;
  }

  /// Check if URL is any media resource (image, video, or audio)
  static bool isMedia(String url) {
    if (url.startsWith('data:') || url.startsWith('blob:')) {
      return false;
    }
    return isImage(url) || isVideo(url) || isAudio(url);
  }

  /// Check if path or query contains any of the extensions
  static bool _hasExtension(String path, String query, List<String> extensions) {
    return extensions.any((ext) =>
      path.endsWith(ext) || query.contains(ext.replaceAll('.', '')));
  }

  /// Check if URL matches any of the given extensions (strict - only in path)
  static bool _checkMediaTypeStrict(String url, List<String> extensions) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath) return false;

    final path = uri.path.toLowerCase();

    // Only check path extension, not query
    return extensions.any((ext) => path.endsWith(ext));
  }

  /// Check if URL matches any of the given extensions
  static bool _checkMediaType(String url, List<String> extensions) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath) return false;

    final path = uri.path.toLowerCase();
    final query = uri.query.toLowerCase();
    final urlLower = url.toLowerCase();

    // Check path extension first (most reliable)
    if (extensions.any((ext) => path.endsWith(ext))) return true;

    // Check query parameter (common for CDN URLs like example.com/image.jpg?w=300)
    // But be more strict - the extension should be followed by = or &
    if (extensions.any((ext) => query.contains('${ext.substring(1)}='))) return true;

    // Check if extension appears before query parameters
    if (extensions.any((ext) => urlLower.contains('${ext.toLowerCase()}?'))) {
      return true;
    }

    return false;
  }

  /// Get media type from URL
  static MediaType? getMediaType(String url) {
    if (isImage(url)) return MediaType.image;
    if (isVideo(url)) return MediaType.video;
    if (isAudio(url)) return MediaType.audio;
    return null;
  }
}
