import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AdPatternLoader {
  AdPatternLoader._();

  static AdPatternLoader? _instance;
  static AdPatternLoader get instance {
    _instance ??= AdPatternLoader._();
    return _instance!;
  }

  final List<String> _patterns = [];
  final List<RegExp> _regexPatterns = [];
  final Set<String> _exactDomains = {};

  bool _isLoaded = false;
  bool _isLoading = false;

  /// Check if patterns are loaded
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  List<String> get patterns => List.unmodifiable(_patterns);

  List<RegExp> get regexPatterns => List.unmodifiable(_regexPatterns);

  Future<void> loadPatterns() async {
    if (_isLoaded || _isLoading) {
      debugPrint('[AdPatternLoader] Patterns already loaded or loading');
      return;
    }

    _isLoading = true;

    try {
      debugPrint('[AdPatternLoader] Loading patterns from assets...');

      final String content = await rootBundle.loadString('assets/block_ad_pattern.txt');

      final result = await Future.microtask(() => compute(_parsePatterns, content)).then((future) => future);

      _patterns.addAll(result['patterns'] as List<String>);
      _regexPatterns.addAll(result['regexPatterns'] as List<RegExp>);
      _exactDomains.addAll(result['exactDomains'] as Set<String>);

      _isLoaded = true;
      _isLoading = false;
      debugPrint('[AdPatternLoader] Loaded ${_patterns.length} substring patterns');
      debugPrint('[AdPatternLoader] Created ${_regexPatterns.length} regex patterns');
      debugPrint('[AdPatternLoader] Indexed ${_exactDomains.length} exact domains');
    } catch (e) {
      debugPrint('[AdPatternLoader] Error loading patterns: $e');
      _isLoaded = true;
      _isLoading = false;
    }
  }

  static Map<String, dynamic> _parsePatterns(String content) {
    final patterns = <String>[];
    final regexPatterns = <RegExp>[];
    final exactDomains = <String>{};

    try {

      final List<String> rawPatterns = content.split('|')
        ..removeWhere((p) => p.trim().isEmpty);

      for (final pattern in rawPatterns) {
        final trimmed = pattern.trim();
        if (trimmed.isEmpty) continue;

        final lowerPattern = trimmed.toLowerCase();

        if (!trimmed.contains('*') && !trimmed.contains('?') && !trimmed.contains('/')) {
          exactDomains.add(lowerPattern);
        } else {
          patterns.add(lowerPattern);
        }
        if (trimmed.contains('*') || trimmed.contains('?')) {
          try {
            final regexPattern = _wildcardToRegexStatic(trimmed);
            regexPatterns.add(regexPattern);
          } catch (e) {
            // Skip invalid regex patterns
          }
        }
      }
    } catch (e) {
      debugPrint('[AdPatternLoader] Error in isolate: $e');
    }

    return {
      'patterns': patterns,
      'regexPatterns': regexPatterns,
      'exactDomains': exactDomains,
    };
  }

  /// Check if URL matches any loaded pattern
  bool matches(String url) {
    if (!_isLoaded) return false;

    final lowerUrl = url.toLowerCase();

    // Fast path: Check exact domains first (O(1) lookup)
    if (_exactDomains.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        final host = uri.host.toLowerCase();
        if (_exactDomains.contains(host)) {
          return true;
        }
      } catch (_) {
        // Invalid URL, continue with other checks
      }
    }

    // Check substring patterns (fast)
    if (_patterns.isNotEmpty) {
      for (final pattern in _patterns) {
        if (lowerUrl.contains(pattern)) {
          return true;
        }
      }
    }

    // Check regex patterns (slower, only if needed)
    if (_regexPatterns.isNotEmpty) {
      for (final regex in _regexPatterns) {
        if (regex.hasMatch(lowerUrl)) {
          return true;
        }
      }
    }

    return false;
  }


  RegExp _wildcardToRegex(String pattern) => _wildcardToRegexStatic(pattern);

  static RegExp _wildcardToRegexStatic(String pattern) {
    String regex = pattern.replaceAllMapped(
      RegExp(r'[.+^${}()|[\]\\]'),
      (match) => '\\${match.group(0)}',
    );

    // Replace wildcards
    regex = regex.replaceAll('*', '.*');
    regex = regex.replaceAll('?', '.');

    return RegExp(regex, caseSensitive: false);
  }

  /// Clear loaded patterns
  void clear() {
    _patterns.clear();
    _regexPatterns.clear();
    _exactDomains.clear();
    _isLoaded = false;
    debugPrint('[AdPatternLoader] Patterns cleared');
  }

  /// Reload patterns
  Future<void> reload() async {
    clear();
    await loadPatterns();
  }

  /// Get statistics
  Map<String, dynamic> get stats => {
    'isLoaded': _isLoaded,
    'substringPatterns': _patterns.length,
    'regexPatterns': _regexPatterns.length,
    'exactDomains': _exactDomains.length,
  };
}
