import 'package:satreps_client_app/features/login/presentation/routes.dart';
import 'package:satreps_client_app/features/slaughterhouse/presentation/routes.dart';

class RouterUtils {
  static final List<String> allowList = [
    LoginRoutes.register,
    LoginRoutes.loginSuccess,
    SlaughterhouseRoutes.slaughterhouseTraceability,
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
