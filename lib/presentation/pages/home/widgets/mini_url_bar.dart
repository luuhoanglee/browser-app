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

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  height: 28,
                  constraints: const BoxConstraints(
                    maxWidth: 250,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
        ),
      ),
    );
  }
}