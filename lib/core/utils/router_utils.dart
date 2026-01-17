
class RouterUtils {
  static final List<String> allowList = [

  ];

  static bool isAllowedRoute(String route) {
    final uri = route;

    for (final allow in allowList) {
      final regex = RegExp('^${RegExp.escape(allow)}(\\?.*)?\$');
      if (regex.hasMatch(uri)) return true;
    }

    return false;
  }
}
