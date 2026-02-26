import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../usecases/analyze_website_usecase.dart';

class WebsiteRepository {
  String? _lastAnalyzedUrl;

  /// Extract meta description from page using JavaScript
  Future<String?> _extractDescription(InAppWebViewController controller) async {
    try {
      final description = await controller.evaluateJavascript(source: '''
        (function() {
          // Try meta name="description"
          var metaDesc = document.querySelector('meta[name="description"]');
          if (metaDesc && metaDesc.content) {
            return metaDesc.content.trim();
          }

          // Try Open Graph description
          var ogDesc = document.querySelector('meta[property="og:description"]');
          if (ogDesc && ogDesc.content) {
            return ogDesc.content.trim();
          }

          // Try Twitter description
          var twDesc = document.querySelector('meta[name="twitter:description"]');
          if (twDesc && twDesc.content) {
            return twDesc.content.trim();
          }

          return '';
        })();
      ''');

      if (description != null && description.isNotEmpty && description != 'null') {
        String cleaned = description.toString().trim();
        // Remove quotes if present
        if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
          cleaned = cleaned.substring(1, cleaned.length - 1);
        }
        // Limit to 500 characters
        if (cleaned.length > 500) {
          cleaned = cleaned.substring(0, 500);
        }
        print('[WebsiteRepository] Got description from JS: ${cleaned.substring(0, 100)}...');
        return cleaned;
      }
    } catch (e) {
      print('[WebsiteRepository] Error getting description from JS: $e');
    }
    return null;
  }

  /// Analyze website with description extracted from page
  Future<void> analyzeWebsite(
    InAppWebViewController controller,
    String url,
  ) async {
    // Skip if same URL was already analyzed in this session
    if (_lastAnalyzedUrl == url) {
      print('[WebsiteRepository] URL already analyzed in session, skipping: $url');
      return;
    }

    // Extract description from page
    final description = await _extractDescription(controller);

    // Mark as analyzed before calling API to avoid race conditions
    _lastAnalyzedUrl = url;

    // Call API with or without description
    await AnalyzeWebsiteUseCase().call(
      AnalyzeWebsiteParams(url: url, description: description),
    );
  }

  /// Reset the last analyzed URL (useful for testing or manual refresh)
  void reset() {
    _lastAnalyzedUrl = null;
  }
}
