import 'package:flutter/material.dart';

class QuickAccessSite {
  final String id;
  final String title;
  final String url;
  final int colorValue;

  const QuickAccessSite({
    required this.id,
    required this.title,
    required this.url,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  String get initial {
    final domain = Uri.tryParse(url)?.host ?? url;
    final clean = domain.replaceFirst('www.', '');
    return clean.isNotEmpty ? clean[0].toUpperCase() : '?';
  }

  factory QuickAccessSite.fromJson(Map<String, dynamic> json) {
    return QuickAccessSite(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      colorValue: json['colorValue'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'colorValue': colorValue,
      };

  QuickAccessSite copyWith({
    String? id,
    String? title,
    String? url,
    int? colorValue,
  }) {
    return QuickAccessSite(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  // Default sites seeded on first launch
  static List<QuickAccessSite> get defaults => [
        const QuickAccessSite(id: 'google',    title: 'Google',    url: 'https://google.com',    colorValue: 0xFF2196F3),
        const QuickAccessSite(id: 'youtube',   title: 'YouTube',   url: 'https://youtube.com',   colorValue: 0xFFF44336),
        const QuickAccessSite(id: 'facebook',  title: 'Facebook',  url: 'https://facebook.com',  colorValue: 0xFF1877F2),
        const QuickAccessSite(id: 'x',         title: 'X',         url: 'https://twitter.com',   colorValue: 0xFF000000),
        const QuickAccessSite(id: 'reddit',    title: 'Reddit',    url: 'https://reddit.com',    colorValue: 0xFFFF4500),
        const QuickAccessSite(id: 'wikipedia', title: 'Wikipedia', url: 'https://wikipedia.org', colorValue: 0xFF757575),
        const QuickAccessSite(id: 'amazon',    title: 'Amazon',    url: 'https://amazon.com',    colorValue: 0xFFFF9900),
        const QuickAccessSite(id: 'github',    title: 'GitHub',    url: 'https://github.com',    colorValue: 0xFF333333),
      ];
}
