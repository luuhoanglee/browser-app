import 'package:satreps_client_app/generated/l10n.dart';
import 'package:satreps_client_app/generated/reverse_map_es.dart';
import 'package:satreps_client_app/generated/translations_lookup.dart';

import 'package:flutter/foundation.dart';

extension TranslateString on String {
  String get tr {
    final loc = AppLocalizations.current;

    String? key;
    Map<String, String> args = {};

    for (var entry in reverseMapEs.entries) {
      final pattern = RegExp.escape(entry.key)
          .replaceAll(RegExp(r'\\{\\w+\\}'), '(.+?)');
      final regex = RegExp('^$pattern\$');

      final match = regex.firstMatch(this);
      if (match != null) {
        key = entry.value;

        // Extract placeholder names
        final paramNames = RegExp(r'{(\w+)}')
            .allMatches(entry.key)
            .map((m) => m.group(1)!)
            .toList();

        for (var i = 0; i < paramNames.length; i++) {
          args[paramNames[i]] = match.group(i + 1)!;
        }
        break;
      }
    }

    if (key != null && translationsLookup.containsKey(key)) {
      return translationsLookup[key]!(loc, args);
    }

    if (kDebugMode) {
      print('[tr] ❌ Missing translation for "$this" (key: $key)');
    }

    return this; // fallback
  }
}

