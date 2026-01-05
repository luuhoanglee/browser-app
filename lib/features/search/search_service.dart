class SearchService {
  SearchService._();

  /// Format input to proper URL
  /// - If input starts with http:// or https://, return as is
  /// - If input contains '.' and no spaces, treat as domain and add https://
  /// - Otherwise, treat as search query and use Google Search
  static String formatUrl(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    if (input.contains('.') && !input.contains(' ')) {
      return 'https://$input';
    }
    return 'https://www.google.com/search?q=${Uri.encodeComponent(input)}';
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
}
