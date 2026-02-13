import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum SearchEngine {
  google,
  bing,
  duckduckgo,
  youtube,
}

extension SearchEngineConfig on SearchEngine {
  String get suggestionEndpoint {
    switch (this) {
      case SearchEngine.google:
        return 'https://suggestqueries.google.com/complete/search?client=firefox&q=';
      case SearchEngine.youtube:
        return 'https://suggestqueries.google.com/complete/search?client=youtube&ds=yt&q=';
      case SearchEngine.bing:
        return 'https://api.bing.com/osjson.aspx?query=';
      case SearchEngine.duckduckgo:
        return 'https://duckduckgo.com/ac/?type=list&q=';
    }
  }

  String get searchBaseUrl {
    switch (this) {
      case SearchEngine.google:
        return 'https://www.google.com/search?q=';
      case SearchEngine.youtube:
        return 'https://www.youtube.com/results?search_query=';
      case SearchEngine.bing:
        return 'https://www.bing.com/search?q=';
      case SearchEngine.duckduckgo:
        return 'https://duckduckgo.com/?q=';
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

  static Future<List<String>> getSuggestions(
    String query, {
    SearchEngine? engine,
  }) async {
    if (query.trim().isEmpty) return [];

    final selectedEngine = engine ?? _defaultEngine;
    final url =
        '${selectedEngine.suggestionEndpoint}${Uri.encodeComponent(query)}';

    final response = await _httpGet(url);
    if (response == null || response.statusCode != 200) return [];

    return _parseSuggestionResponse(selectedEngine, response.body);
  }

  static String buildSearchUrl(String query,
      {SearchEngine? engine}) {
    final selectedEngine = engine ?? _defaultEngine;
    final encoded = Uri.encodeComponent(query);
    return '${selectedEngine.searchBaseUrl}$encoded';
  }

  static String formatInput(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) return '';

    if (_isValidUrl(trimmed)) return trimmed;

    if (_isLikelyDomain(trimmed)) {
      return 'https://$trimmed';
    }

    return buildSearchUrl(trimmed);
  }

  static bool isUrl(String input) {
    return _isValidUrl(input) || _isLikelyDomain(input);
  }

  static String getDisplayUrl(String url) {
    return url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '');
  }

  static String? getDomain(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> fetchTrending({
    SearchEngine? engine,
    int limit = 6,
  }) async {
    final selectedEngine = engine ?? _defaultEngine;

    // Seed queries based on common trending patterns
    final seeds = _getTrendingSeeds(selectedEngine);

    final results = <String>{};

    for (final seed in seeds) {
      final suggestions =
          await getSuggestions(seed, engine: selectedEngine);

      results.addAll(suggestions);
      await Future.delayed(const Duration(milliseconds: 120));
    }

    final list = results.toList()..shuffle();
    return list.take(limit).toList();
  }


  static List<String> _parseSuggestionResponse(
      SearchEngine engine, String body) {
    try {
      final cleaned = _extractYoutubeWrapper(body);

      if (!cleaned.trim().startsWith('[')) return [];

      final decoded = jsonDecode(cleaned) as List;
      if (decoded.length < 2) return [];

      final data = decoded[1];

      if (engine == SearchEngine.youtube) {
        return (data as List)
            .where((item) => item is List && item.isNotEmpty)
            .map((item) => item[0].toString())
            .toList();
      }

      return (data as List)
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _extractYoutubeWrapper(String body) {
    if (!body.startsWith('window.google.ac.h(')) return body;

    final start = body.indexOf('[');
    final end = body.lastIndexOf(']');

    if (start != -1 && end != -1) {
      return body.substring(start, end + 1);
    }

    return body;
  }

  static bool _isValidUrl(String input) {
    final uri = Uri.tryParse(input);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  static bool _isLikelyDomain(String input) {
    final uri = Uri.tryParse(input);
    return uri != null &&
        !uri.hasScheme &&
        uri.host.contains('.') &&
        !input.contains(' ');
  }

  static List<String> _getTrendingSeeds(SearchEngine engine) {
    switch (engine) {
      case SearchEngine.youtube:
        return ['trending', 'viral', 'new', 'game', 'review'];
      case SearchEngine.google:
        return ['today', 'latest', 'news', 'hot', 'review'];
      case SearchEngine.bing:
        return ['today', 'latest', 'news', 'hot'];
      case SearchEngine.duckduckgo:
        return ['news', 'popular', 'today'];
    }
  }

  static Future<_HttpResponse?> _httpGet(String url) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse(url));

      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      );

      final response =
          await request.close().timeout(const Duration(seconds: 10));

      final body = await response.transform(utf8.decoder).join();

      return _HttpResponse(response.statusCode, body);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

class _HttpResponse {
  final int statusCode;
  final String body;

  _HttpResponse(this.statusCode, this.body);
}