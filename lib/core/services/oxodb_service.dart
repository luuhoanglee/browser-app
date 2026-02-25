import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebsiteInfo {
  final String url;
  final String description;
  final String title;
  final DateTime timestamp;

  WebsiteInfo({
    required this.url,
    required this.description,
    required this.title,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'description': description,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WebsiteInfo.fromJson(Map<String, dynamic> json) {
    return WebsiteInfo(
      url: json['url'] as String,
      description: json['description'] as String? ?? '',
      title: json['title'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class OxodbService {
  static const String _baseUrl = 'https://api.oxodb.com/api/websites/analyze';
  static const String _cacheKey = 'oxodb_cache';

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static final Set<String> _processedUrls = {};
  static bool _isInitialized = false;

  static Future<void> _initCache() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      if (cacheJson != null) {
        final List<dynamic> cacheList = jsonDecode(cacheJson);
        for (var item in cacheList) {
          final info = WebsiteInfo.fromJson(item as Map<String, dynamic>);
          _processedUrls.add(info.url);
        }
      }
      _isInitialized = true;
      print('[OxodbService] Cache loaded: ${_processedUrls.length} URLs');
    } catch (e) {
      print('[OxodbService] Error loading cache: $e');
      _isInitialized = true;
    }
  }

  static Future<void> _saveToCache(String url, String description, String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      List<WebsiteInfo> cacheList = [];
      if (cacheJson != null) {
        final List<dynamic> decoded = jsonDecode(cacheJson);
        cacheList = decoded
            .map((item) => WebsiteInfo.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      cacheList.removeWhere((info) => info.url == url);
      cacheList.add(WebsiteInfo(
        url: url,
        description: description,
        title: title,
        timestamp: DateTime.now(),
      ));

      if (cacheList.length > 1000) {
        cacheList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        cacheList = cacheList.sublist(0, 1000);
      }

      await prefs.setString(_cacheKey, jsonEncode(cacheList.map((e) => e.toJson()).toList()));
      _processedUrls.add(url);
      print('[OxodbService] Saved to cache: $url');
    } catch (e) {
      print('[OxodbService] Error saving cache: $e');
    }
  }

  static bool _isUrlProcessed(String url) {
    return _processedUrls.contains(url);
  }

  /// Clean URL - only keep host (domain)
  static String _cleanUrl(String url) {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}';
  }

  /// Extract title from URL (domain name without www and extension)
  static String _extractTitleFromUrl(String url) {
    final uri = Uri.parse(url);
    String host = uri.host;

    // Remove www. prefix
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }

    // Remove extension (.com, .net, .cv, .icu, etc.)
    final parts = host.split('.');
    if (parts.length >= 2) {
      return parts.sublist(0, parts.length - 1).join('.');
    }

    return host;
  }

  /// Fetch website HTML and extract meta description
  static Future<String> _fetchWebsiteDescription(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );

      if (response.statusCode == 200 && response.data is String) {
        return _extractMetaDescription(response.data as String);
      }
    } catch (e) {
      print('[OxodbService] Error fetching description: $e');
    }
    return '';
  }

  static String _extractMetaDescription(String html) {
    String descPattern = r'''<meta\s+name=["']description["']\s+content=["']([^"']*)["']''';
    final match = RegExp(descPattern, caseSensitive: false).firstMatch(html);

    if (match != null && match.groupCount >= 1) {
      final description = match.group(1)?.trim() ?? '';
      if (description.length > 500) {
        return description.substring(0, 500);
      }
      return description;
    }

    String ogPattern = r'''<meta\s+property=["']og:description["']\s+content=["']([^"']*)["']''';
    final ogMatch = RegExp(ogPattern, caseSensitive: false).firstMatch(html);

    if (ogMatch != null && ogMatch.groupCount >= 1) {
      final description = ogMatch.group(1)?.trim() ?? '';
      if (description.length > 500) {
        return description.substring(0, 500);
      }
      return description;
    }

    return '';
  }

  static Future<void> analyzeWebsite(String url, {String? description, String? title}) async {
    if (url.isEmpty || !url.startsWith('http')) {
      return;
    }

    final cleanedUrl = _cleanUrl(url);
    await _initCache();

    if (_isUrlProcessed(cleanedUrl)) {
      print('[OxodbService] URL already processed, skipping: $cleanedUrl');
      return;
    }

    String finalDescription = description ?? '';
    String finalTitle = title ?? _extractTitleFromUrl(url);

    if (finalDescription.isEmpty) {
      try {
        finalDescription = await _fetchWebsiteDescription(url);
        print('[OxodbService] Fetched - Description: ${finalDescription.isNotEmpty ? finalDescription.substring(0, 100) : "empty"}...');
      } catch (e) {
        print('[OxodbService] Error fetching description: $e');
      }
    }

    try {
      final body = {
        'url': cleanedUrl,
        'metadata': {
          'description': finalDescription,
          'title': finalTitle,
        },
      };

      print('[OxodbService] Sending request - URL: $cleanedUrl');
      print('[OxodbService] Title: $finalTitle');
      print('[OxodbService] Description length: ${finalDescription.length}');

      final response = await _dio.post(
        _baseUrl,
        data: body,
      );

      print('[OxodbService] Success: ${response.statusCode} - ${response.data}');
      await _saveToCache(cleanedUrl, finalDescription, finalTitle);
    } catch (e) {
      print('[OxodbService] Error: $e');
      await _saveToCache(cleanedUrl, finalDescription, finalTitle);
    }
  }

  static Future<WebsiteInfo?> getCachedInfo(String url) async {
    await _initCache();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      if (cacheJson != null) {
        final List<dynamic> cacheList = jsonDecode(cacheJson);
        for (var item in cacheList) {
          final info = WebsiteInfo.fromJson(item as Map<String, dynamic>);
          if (info.url == url) {
            return info;
          }
        }
      }
    } catch (e) {
      print('[OxodbService] Error getting cached info: $e');
    }
    return null;
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      _processedUrls.clear();
      print('[OxodbService] Cache cleared');
    } catch (e) {
      print('[OxodbService] Error clearing cache: $e');
    }
  }
}
