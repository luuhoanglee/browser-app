import 'package:flutter/material.dart';
import '../../../../features/search/search_service.dart';

class SearchEngineSheet extends StatelessWidget {
  final SearchEngine currentEngine;
  final Function(SearchEngine) onEngineSelected;

  const SearchEngineSheet({
    super.key,
    required this.currentEngine,
    required this.onEngineSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Engine',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
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
          // Engine list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: SearchEngine.values.length,
              itemBuilder: (context, index) {
                final engine = SearchEngine.values[index];
                final isSelected = engine == currentEngine;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: _buildEngineIcon(engine),
                    title: Text(
                      engine.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.blue : Colors.grey[800],
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Colors.blue, size: 24)
                        : Icon(Icons.circle_outlined, color: Colors.grey[400], size: 24),
                    onTap: () {
                      onEngineSelected(engine);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          // Keyword guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Keywords',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildKeywordChip('g', 'Google'),
                    _buildKeywordChip('b', 'Bing'),
                    _buildKeywordChip('d', 'DuckDuckGo'),
                    _buildKeywordChip('y', 'YouTube'),
                    _buildKeywordChip('w', 'Wikipedia'),
                    _buildKeywordChip('gh', 'GitHub'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Example: "flutter tutorial gh" → Search on GitHub',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineIcon(SearchEngine engine) {
    IconData icon;
    Color color;

    switch (engine) {
      case SearchEngine.google:
        icon = Icons.search;
        color = Colors.blue;
        break;
      case SearchEngine.bing:
        icon = Icons.search;
        color = Colors.cyan;
        break;
      case SearchEngine.duckduckgo:
        icon = Icons.shield;
        color = Colors.orange;
        break;
      case SearchEngine.youtube:
        icon = Icons.play_circle_filled;
        color = Colors.red;
        break;
      case SearchEngine.wikipedia:
        icon = Icons.menu_book;
        color = Colors.grey;
        break;
      case SearchEngine.github:
        icon = Icons.code;
        color = Colors.black;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildKeywordChip(String keyword, String engine) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$keyword → $engine',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
