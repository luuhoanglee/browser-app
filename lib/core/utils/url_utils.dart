class UrlUtils {
  const UrlUtils._();

  static String formatUrl(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    if (input.contains('.') && !input.contains(' ')) {
      return 'https://$input';
    }
    return 'https://www.google.com/search?q=${Uri.encodeComponent(input)}';
  }

  static String formatUrlTitle(String url) {
    if (url.startsWith('https://')) {
      url = url.substring(8);
    } else if (url.startsWith('http://')) {
      url = url.substring(7);
    }
    final parts = url.split('/');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return url;
  }

  static String? scheme(String url) {
    final i = url.indexOf('://');
    return i == -1 ? null : url.substring(0, i).toLowerCase();
  }

  static bool isExternalUrl(String url) {
    final s = scheme(url.toLowerCase());
    const externalSchemes = {
      'googlechrome',
      'chrome',
      'firefox',
      'edge',
      'opera',
    };
    return s != null && externalSchemes.contains(s);
  }
}
