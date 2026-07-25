import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MiniUrlBar extends StatelessWidget {
  final dynamic activeTab;
  final InAppWebViewController? controller;
  final VoidCallback onTap;

  const MiniUrlBar({
    super.key,
    required this.activeTab,
    required this.controller,
    required this.onTap,
  });

  String _formatDisplayUrl(String url) {
    if (url.startsWith('https://')) {
      url = url.substring(8);
    } else if (url.startsWith('http://')) {
      url = url.substring(7);
    }

    // Chỉ lấy domain, không lấy path phía sau
    final parts = url.split('/');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return url;
  }


  @override
  Widget build(BuildContext context) {
    final displayUrl = _formatDisplayUrl(activeTab.url);

    // The mini bar floats over the page content at the very bottom of the
    // screen. Only the pill itself is hit-testable, so touches in the
    // surrounding transparent area pass through to the page (scroll/tap the
    // web content). Only the bottom inset (gesture nav bar) is relevant here —
    // applying the top (status bar) inset would push the pill downward. The bar
    // paints nothing behind the pill, so no white strip is exposed on dark
    // pages. See issue #21.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 28,
              constraints: const BoxConstraints(
                maxWidth: 250,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Domain name
                  Flexible(
                    child: Text(
                      displayUrl.isNotEmpty ? displayUrl : '...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}