import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchBarWidget extends StatefulWidget {
  final String currentUrl;
  final Function(String) onSearch;

  const SearchBarWidget({
    super.key,
    required this.currentUrl,
    required this.onSearch,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUrl);
  }

  @override
  void didUpdateWidget(SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      _controller.text = widget.currentUrl;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getSearchQuery(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    if (input.contains('.') && !input.contains(' ')) {
      return 'https://$input';
    }
    return 'https://www.google.com/search?q=${Uri.encodeComponent(input)}';
  }

  void _handleSubmit() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      final url = _getSearchQuery(query);
      widget.onSearch(url);
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: _controller,
        onTap: () {
          setState(() {
            _isEditing = true;
          });
          _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
        },
        onSubmitted: (_) => _handleSubmit(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search or enter URL',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _isEditing
              ? IconButton(
                  icon: const Icon(Icons.check, color: Colors.blue),
                  onPressed: _handleSubmit,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
