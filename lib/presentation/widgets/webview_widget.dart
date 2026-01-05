import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewWidget extends StatefulWidget {
  final String initialUrl;
  final Function(InAppWebViewController)? onWebViewCreated;
  final Function(String)? onUrlChanged;
  final Function(String)? onTitleChanged;
  final Function(bool)? onLoadingChanged;

  const WebViewWidget({
    super.key,
    required this.initialUrl,
    this.onWebViewCreated,
    this.onUrlChanged,
    this.onTitleChanged,
    this.onLoadingChanged,
  });

  @override
  State<WebViewWidget> createState() => _WebViewWidgetState();
}

class _WebViewWidgetState extends State<WebViewWidget> {
  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      onWebViewCreated: (controller) {
        widget.onWebViewCreated?.call(controller);
      },
      onLoadStart: (controller, url) {
        widget.onLoadingChanged?.call(true);
        if (url != null) {
          widget.onUrlChanged?.call(url.toString());
        }
      },
      onLoadStop: (controller, url) {
        widget.onLoadingChanged?.call(false);
        if (url != null) {
          widget.onUrlChanged?.call(url.toString());
        }
      },
      onTitleChanged: (controller, title) {
        if (title != null) {
          widget.onTitleChanged?.call(title);
        }
      },
      onProgressChanged: (controller, progress) {
        if (progress == 100) {
          widget.onLoadingChanged?.call(false);
        }
      },
    );
  }
}
