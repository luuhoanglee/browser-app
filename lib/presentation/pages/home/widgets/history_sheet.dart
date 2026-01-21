import 'package:flutter/material.dart';

class HistorySheet extends StatefulWidget {
  final List<String> history;
  final Function(String) onSelectHistory;
  final VoidCallback onClearHistory;
  final Function(String) onRemoveHistory;

  const HistorySheet({
    super.key,
    required this.history,
    required this.onSelectHistory,
    required this.onClearHistory,
    required this.onRemoveHistory,
  });

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  late List<String> _localHistory;

  @override
  void initState() {
    super.initState();
    _localHistory = List.from(widget.history);
  }

  void _handleClear() {
    widget.onClearHistory();
    setState(() {
      _localHistory.clear();
    });
  }

  void _handleRemove(String url) {
    widget.onRemoveHistory(url);
    setState(() {
      _localHistory.remove(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${_localHistory.length} History',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (_localHistory.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _handleClear,
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 17,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 20, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
          // History list
          Expanded(
            child: _localHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No history yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: _localHistory.length,
                    itemBuilder: (context, index) {
                      final url = _localHistory[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(Icons.history, size: 20, color: Colors.grey[600]),
                          title: Text(
                            _formatUrl(url),
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: GestureDetector(
                            onTap: () => _handleRemove(url),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                          ),
                          onTap: () {
                            widget.onSelectHistory(url);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
          // Done button
          Container(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatUrl(String url) {
    if (url.startsWith('https://')) {
      return url.substring(8);
    } else if (url.startsWith('http://')) {
      return url.substring(7);
    }
    return url;
  }
}
