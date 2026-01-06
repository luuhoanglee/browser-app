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
  });

  @override
  Widget build(BuildContext context) {
    print('🔨 Building WebViewPage for ${activeTab.url} (id: ${activeTab.id})');

    return RepaintBoundary(
      child: InAppWebView(
      key: ValueKey(activeTab.id),
      initialUrlRequest: activeTab.url.isEmpty
          ? null
          : URLRequest(url: WebUri(activeTab.url)),
      initialSettings: InAppWebViewSettings(
        disallowOverScroll: false,
        useShouldOverrideUrlLoading: true,
        useOnLoadResource: true,
        useOnDownloadStart: true,
      ),
      onWebViewCreated: (controller) async {
        print('✅ WebView created for ${activeTab.id}');
        onWebViewCreated(controller);

        // Cập nhật settings sau khi tạo
        await controller.setSettings(settings: InAppWebViewSettings(
          disallowOverScroll: false,
        ));
        print('✅ Settings updated');

        // Không cần loadUrl ở đây vì initialUrlRequest đã xử lý
        // Chỉ load nếu URL rỗng và cần load sau
        if (activeTab.url.isEmpty) {
          print('⚠️ No URL to load in onWebViewCreated');
        }
      },
      onLoadStart: (controller, url) {
        print('📄 Page loading: $url');
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
      ),
    );
  }
}
