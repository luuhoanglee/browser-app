import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' show InAppWebViewController, WebUri;

class WebViewPage extends StatelessWidget {
  final dynamic activeTab;
  final InAppWebViewController? controller;
  final Function(InAppWebViewController) onWebViewCreated;
  final Function(InAppWebViewController, WebUri?) onLoadStart;
  final Function(InAppWebViewController, WebUri?) onLoadStop;
  final Function(InAppWebViewController, String?) onTitleChanged;
  final Function(InAppWebViewController, int) onProgressChanged;
  final Function(int) onScrollChanged;
  final Function(String)? onUrlUpdated;

  const WebViewPage({
    super.key,
    required this.activeTab,
    required this.controller,
    required this.onWebViewCreated,
    required this.onLoadStart,
    required this.onLoadStop,
    required this.onTitleChanged,
    required this.onProgressChanged,
    required this.onScrollChanged,
    this.onUrlUpdated,
  });

  /// Parse intent:// URL thành https:// URL
  /// Ví dụ: intent://example.com#Intent;scheme=https;package=com.android.chrome;end
  ///       => https://example.com
  static String? parseIntentUrl(String url) {
    if (!url.startsWith('intent://')) return null;

    try {
      // Lấy phần trước #Intent
      final uriParts = url.split('#Intent');
      if (uriParts.isEmpty) return null;

      String targetUrl = uriParts[0].replaceFirst('intent://', 'https://');

      // Parse tham số scheme
      final intentParams = uriParts.length > 1 ? uriParts[1] : '';
      final schemeMatch = RegExp(r'scheme=([^;]+)').firstMatch(intentParams);

      if (schemeMatch != null) {
        final scheme = schemeMatch.group(1);
        if (scheme != null && scheme != 'http' && scheme != 'https') {
          // Scheme không phải http/https, không xử lý
          return null;
        }
      }

      return targetUrl;
    } catch (e) {
      print('❌ Error parsing intent URL: $e');
      return null;
    }
  }

  /// Kiểm tra URL có phải là external URL cần redirect không
  static bool isExternalUrl(String url) {
    return url.startsWith('intent://') ||
           url.startsWith('googlechrome://') ||
           url.startsWith('firefox://') ||
           url.startsWith('chrome://') ||
           url.startsWith('edge://') ||
           url.startsWith('opera://');
  }

  @override
  Widget build(BuildContext context) {
    print('🔨 Building WebViewPage for ${activeTab.url} (id: ${activeTab.id})');

    // Parse intent URL nếu có trước khi load
    String initialUrl = activeTab.url ?? '';
    if (initialUrl.isNotEmpty && isExternalUrl(initialUrl)) {
      final parsed = parseIntentUrl(initialUrl);
      if (parsed != null) {
        initialUrl = parsed;
        print('🔄 Pre-parsed intent URL to: $initialUrl');
        // Thông báo cho HomePage để cập nhật tab URL
        onUrlUpdated?.call(initialUrl);
      } else {
        initialUrl = '';
        print('🚫 Blocked external URL: ${activeTab.url}');
        onUrlUpdated?.call('');
      }
    }

    return RepaintBoundary(
      child: InAppWebView(
      key: ValueKey(activeTab.id),
      initialUrlRequest: initialUrl.isEmpty
          ? null
          : URLRequest(url: WebUri(initialUrl)),
      initialSettings: InAppWebViewSettings(
        disallowOverScroll: false,
        useShouldOverrideUrlLoading: true,
        useOnLoadResource: true,
        useOnDownloadStart: true,
        // JavaScript enabled để inject code chặn intent
        javaScriptEnabled: true,
      ),
      onWebViewCreated: (controller) async {
        print('✅ WebView created for ${activeTab.id}');
        onWebViewCreated(controller);

        // Cập nhật settings sau khi tạo
        await controller.setSettings(settings: InAppWebViewSettings(
          disallowOverScroll: false,
        ));
        print('✅ Settings updated');

        // Inject JavaScript để chặn intent redirects
        await controller.setSettings(settings: InAppWebViewSettings(
          userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
        ));

        // Add user script để chặn intent redirects trước khi page load
        final blockIntentScript = """
          (function() {
            // Override window.location to block intent:// redirects
            const originalLocation = window.location;
            Object.defineProperty(window, 'location', {
              get: function() { return originalLocation; },
              set: function(url) {
                if (typeof url === 'string' && url.startsWith('intent://')) {
                  console.log('Blocked intent redirect:', url);
                  // Parse and redirect to https instead
                  const match = url.match(/intent:\/\/([^#]+)/);
                  if (match) {
                    const targetUrl = 'https://' + match[1];
                    console.log('Redirecting to:', targetUrl);
                    originalLocation.href = targetUrl;
                  }
                  return;
                }
                originalLocation.href = url;
              }
            });

            // Block intent:// in iframes
            const originalCreateElement = document.createElement;
            document.createElement = function(tagName) {
              const element = originalCreateElement.call(document, tagName);
              if (tagName.toLowerCase() === 'iframe') {
                element.addEventListener('load', function() {
                  const src = element.src;
                  if (src && src.startsWith('intent://')) {
                    console.log('Blocked iframe intent:', src);
                    element.src = '';
                  }
                });
              }
              return element;
            };
          })();
        """;

        await controller.addUserScript(userScript: UserScript(
          source: blockIntentScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          contentWorld: ContentWorld.PAGE,
        ));
        print('✅ Injected intent blocking script');

        // Load URL nếu có và chưa được load bởi initialUrlRequest
        if (initialUrl.isNotEmpty) {
          print('🌐 Loading URL in onWebViewCreated: $initialUrl');
          await controller.loadUrl(urlRequest: URLRequest(url: WebUri(initialUrl)));
        }
      },
      onLoadStart: (controller, url) {
        print('📄 Page loading: $url');

        // Chặn và redirect intent:// URLs ngay khi bắt đầu load
        if (url != null) {
          final urlStr = url.toString();
          if (urlStr.startsWith('intent://')) {
            print('🚫 Detected intent URL in onLoadStart, blocking...');
            final parsedUrl = parseIntentUrl(urlStr);
            if (parsedUrl != null) {
              print('✅ Redirecting intent to: $parsedUrl');
              // Dừng loading hiện tại trước khi redirect
              controller.stopLoading();
              // Load URL đã parse sau một delay nhỏ
              Future.delayed(const Duration(milliseconds: 100), () {
                controller.loadUrl(urlRequest: URLRequest(url: WebUri(parsedUrl)));
              });
            }
            // Không gọi onLoadStart callback để không update tab với URL intent
            return;
          }
        }

        onLoadStart(controller, url);
      },
      onLoadStop: (controller, url) {
        print('✅ Page loaded: $url');
        onLoadStop(controller, url);
      },
      onTitleChanged: (controller, title) {
        print('📝 Title changed: $title');
        onTitleChanged(controller, title);
      },
      onProgressChanged: (controller, progress) {
        onProgressChanged(controller, progress);
      },
      onScrollChanged: (controller, x, y) {
        // print('📜 Scroll: x=$x, y=$y');
        onScrollChanged(y);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url.toString();

        print('🔗 shouldOverrideUrlLoading: $url');

        // Xử lý intent:// URLs
        if (url.startsWith('intent://')) {
          final parsedUrl = WebViewPage.parseIntentUrl(url);
          if (parsedUrl != null) {
            print('✅ Parsed intent URL to: $parsedUrl');
            // Load URL đã parse và CANCEL navigation hiện tại
            await controller.loadUrl(urlRequest: URLRequest(url: WebUri(parsedUrl)));
            return NavigationActionPolicy.CANCEL;
          }
          // Không thể parse, CANCEL navigation
          print('❌ Cannot parse intent URL, cancelling navigation');
          return NavigationActionPolicy.CANCEL;
        }

        // Xử lý các external URLs khác
        if (WebViewPage.isExternalUrl(url)) {
          print('❌ External URL detected, cancelling navigation: $url');
          return NavigationActionPolicy.CANCEL;
        }

        // Cho phép các URL khác
        return NavigationActionPolicy.ALLOW;
      },
      ),
    );
  }
}
