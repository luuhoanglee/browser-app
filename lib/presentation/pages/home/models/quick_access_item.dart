import 'package:flutter/material.dart';

class QuickAccessItem {
  final String title;
  final String url;
  final IconData icon;
  final Color color;

  const QuickAccessItem({
    required this.title,
    required this.url,
    required this.icon,
    required this.color,
  });
}
