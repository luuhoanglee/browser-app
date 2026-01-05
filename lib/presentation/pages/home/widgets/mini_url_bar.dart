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

  bool _isSecure(String url) {
    return url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _formatDisplayUrl(activeTab.url);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, -1),
                blurRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Icon(
                      _isSecure(activeTab.url) ? Icons.lock_outline : Icons.public,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayUrl.isNotEmpty ? displayUrl : '...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!activeTab.isLoading)
                    GestureDetector(
                      onTap: () => controller?.reload(),
                      child: SizedBox(
                        width: 22,
                        child: Icon(
                          Icons.refresh,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
