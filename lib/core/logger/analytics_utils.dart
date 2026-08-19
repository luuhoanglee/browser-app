import 'package:browser_app/core/logger/analytics_event.dart';

abstract final class AnalyticsUtils {
  static String? domainFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    final host = uri?.host;
    if (host == null || host.isEmpty) return null;

    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static String fileTypeFromName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'unknown';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  static Map<String, Object> navigationParams(String? url) {
    final domain = domainFromUrl(url);
    if (domain == null) return const {};
    return {AnalyticsParam.domain: domain};
  }
}
