import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/quick_access_bloc.dart';
import '../bloc/quick_access_event.dart';
import '../models/quick_access_site.dart';

const _kPalette = [
  Color(0xFF2196F3), // blue
  Color(0xFFF44336), // red
  Color(0xFF4CAF50), // green
  Color(0xFFFF9800), // orange
  Color(0xFF9C27B0), // purple
  Color(0xFF009688), // teal
  Color(0xFFE91E63), // pink
  Color(0xFF3F51B5), // indigo
  Color(0xFF795548), // brown
  Color(0xFF607D8B), // blue grey
  Color(0xFF000000), // black
  Color(0xFF757575), // grey
];

class AddSiteSheet extends StatefulWidget {
  const AddSiteSheet({super.key});

  @override
  State<AddSiteSheet> createState() => _AddSiteSheetState();
}

class _AddSiteSheetState extends State<AddSiteSheet> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  Color _selectedColor = _kPalette[0];
  String? _urlError;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _normalizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  void _onUrlChanged(String value) {
    if (_urlError != null) setState(() => _urlError = null);
    // Auto-fill name from URL if name is still empty
    if (_nameController.text.isEmpty) {
      final uri = Uri.tryParse(_normalizeUrl(value));
      final host = uri?.host.replaceFirst('www.', '') ?? '';
      if (host.isNotEmpty) {
        final parts = host.split('.');
        if (parts.isNotEmpty) {
          final name = parts[0];
          _nameController.text =
              name[0].toUpperCase() + name.substring(1);
        }
      }
    }
  }

  void _submit() {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() => _urlError = 'Please enter a URL');
      return;
    }
    final url = _normalizeUrl(rawUrl);
    if (!_isValidUrl(url)) {
      setState(() => _urlError = 'Invalid URL');
      return;
    }

    final title = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : Uri.parse(url).host.replaceFirst('www.', '');

    final site = QuickAccessSite(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      url: url,
      colorValue: _selectedColor.value,
    );

    context.read<QuickAccessBloc>().add(QuickAccessAddEvent(site));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add Website',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          // URL field
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autofocus: true,
            onChanged: _onUrlChanged,
            decoration: InputDecoration(
              labelText: 'URL',
              hintText: 'e.g. google.com',
              errorText: _urlError,
              prefixIcon: const Icon(Icons.link_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6B5CE7), width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Name field
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Name (optional)',
              hintText: 'Display name',
              prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6B5CE7), width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          // Color picker
          const Text(
            'Icon Color',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _kPalette.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2.5)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Add button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5CE7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
