import 'dart:convert';
import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

enum SearchEngine {
  google,
  bing,
  duckduckgo,
  youtube,
}

extension SearchEngineExtension on SearchEngine {
  /// API endpoint for search suggestions
  String get apiSearchSuggest {
    switch (this) {
      case SearchEngine.bing:
        return 'https://api.bing.com/osjson.aspx?query=';
      case SearchEngine.google:
        return 'https://suggestqueries.google.com/complete/search?client=firefox&q=';
      case SearchEngine.youtube:
        return 'https://suggestqueries.google.com/complete/search?hl=en&ds=yt&client=youtube&hjson=t&cp=1&q=';
      case SearchEngine.duckduckgo:
        return 'https://duckduckgo.com/ac/?type=list&q=';
    }
  }

  /// API endpoint for trending searches (if available)
  String? get apiTrending {
    switch (this) {
      case SearchEngine.google:
        return 'https://trends.google.com/trends/api/dailytrends';
      case SearchEngine.youtube:
        return 'https://yt.lemnoslife.com/videos?part=short&id=';
      default:
        return null;
    }
  }

  /// Get search suggestions from the selected search engine
  Future<List<String>> getSearchSuggest(String query) async {
    try {
      SearchEngine searchEngine = this;
      if (query.isEmpty) {
        searchEngine = SearchEngine.bing;
      }

      final response = await http.get(Uri.parse('${searchEngine.apiSearchSuggest}$query'));
      if (response.statusCode != 200) {
        return [];
      }

      switch (searchEngine) {
        case SearchEngine.bing:
          final decoded = jsonDecode(response.body) as List;
          final data = decoded[1] as List;
          final List<String> list = [];
          for (int i = 0; i < data.length; i++) {
            list.add(data[i].toString());
          }
          return list;

        case SearchEngine.google:
          final decoded = jsonDecode(response.body) as List;
          if (decoded.length > 1) {
            final data = decoded[1] as List;
            final List<String> list = [];
            for (int i = 0; i < data.length; i++) {
              list.add(data[i].toString());
            }
            return list;
          }
          return [];

        case SearchEngine.youtube:
          final decoded = jsonDecode(response.body) as List;
          final data = decoded[1] as List;
          final List<String> list = [];
          for (int i = 0; i < data.length; i++) {
            list.add(data[i][0].toString());
          }
          return list;

        case SearchEngine.duckduckgo:
          final decoded = jsonDecode(response.body) as List;
          final data = decoded[1] as List;
          final List<String> list = [];
          for (int i = 0; i < data.length; i++) {
            list.add(data[i].toString());
          }
          return list;
      }
    } catch (e) {
      print('getSearchSuggest error: $e');
      return [];
    }
  }
}

class SearchService {
  SearchService._();

  static SearchEngine _defaultEngine = SearchEngine.google;

  static SearchEngine get defaultEngine => _defaultEngine;

  static void setDefaultEngine(SearchEngine engine) {
    _defaultEngine = engine;
  }

  static String getSearchUrl(SearchEngine engine, String query) {
    switch (engine) {
      case SearchEngine.google:
        return 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
      case SearchEngine.bing:
        return 'https://www.bing.com/search?q=${Uri.encodeComponent(query)}';
      case SearchEngine.duckduckgo:
        return 'https://duckduckgo.com/?q=${Uri.encodeComponent(query)}';
      case SearchEngine.youtube:
        return 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}';
    }
  }

  static String formatUrlWithKeyword(String query) {
    return getSearchUrl(_defaultEngine, query);
  }

  /// Format input to proper URL
  /// - If input starts with http:// or https://, return as is
  /// - If input contains '.' and no spaces, treat as domain and add https://
  /// - Otherwise, treat as search query and use selected search engine
  static String formatUrl(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    if (input.contains('.') && !input.contains(' ')) {
      return 'https://$input';
    }
    return getSearchUrl(_defaultEngine, input);
  }

  /// Check if input is a valid URL format
  static bool isUrl(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return true;
    }
    if (input.contains('.') && !input.contains(' ')) {
      return true;
    }
    return false;
  }

  /// Extract search query from Google Search URL
  static String? extractSearchQuery(String url) {
    if (url.contains('google.com/search')) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        return uri.queryParameters['q'];
      }
    }
    return null;
  }

  /// Get display URL (remove http://, https://, www.)
  static String getDisplayUrl(String url) {
    String displayUrl = url;
    if (displayUrl.startsWith('https://')) {
      displayUrl = displayUrl.substring(8);
    } else if (displayUrl.startsWith('http://')) {
      displayUrl = displayUrl.substring(7);
    }
    if (displayUrl.startsWith('www.')) {
      displayUrl = displayUrl.substring(4);
    }
    return displayUrl;
  }

  /// Get domain from URL
  static String? getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Fetch trending searches using multiple popular queries
  static Future<List<String>> fetchTrendingSearches({
    String region = 'VN',
    int limit = 6,
  }) async {
    print('🔍 [Trending] Starting fetch...');

    // Use Google Suggest API with common letters to get popular searches
    final queries = [
  'hot',
  'mới',
  '2025',
  'hôm nay',
  'top',
  'review',
  'giá',
];

    final allSuggestions = <String>{};

    for (final q in queries) {
      final url = 'https://suggestqueries.google.com/complete/search?client=firefox&hl=$region&q=$q';
      print('🔍 [Trending] Fetching suggestions for: $q');

      final response = await _httpGet(url);

      if (response != null && response.statusCode == 200) {
        final body = response.body;
        print('🔍 [Trending] Response for "$q": ${body.length} bytes');

        // Google Suggest returns: ["a",["suggestion1","suggestion2",...]]
        if (body.startsWith('[')) {
          final jsonData = jsonDecode(body);
          if (jsonData is List && jsonData.length > 1) {
            final suggestions = jsonData[1] as List;
            for (final s in suggestions) {
              if (s is String && s.isNotEmpty) {
                allSuggestions.add(s);
              }
            }
          }
        }
      }

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final trends = allSuggestions.toList()..shuffle();
    final result = trends.take(limit).toList();

    print('🔍 [Trending] Total suggestions found: ${allSuggestions.length}');
    print('🔍 [Trending] Returning ${result.length} trending searches');
    return result;
  }

  static Future<_HttpResponse?> _httpGet(String url) async {
    try {
      final client = io.HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();
      return _HttpResponse(response.statusCode, responseBody);
    } catch (e) {
      return null;
    }
  }
}

class _HttpResponse {
  final int statusCode;
  final String body;

  _HttpResponse(this.statusCode, this.body);
}
