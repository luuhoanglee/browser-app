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

  static const List<QuickAccessItem> defaults = [
    QuickAccessItem(
      title: 'Google',
      url: 'google.com',
      icon: Icons.search,
      color: Colors.blue,
    ),
    QuickAccessItem(
      title: 'YouTube',
      url: 'youtube.com',
      icon: Icons.play_circle_filled,
      color: Colors.red,
    ),
    QuickAccessItem(
      title: 'Facebook',
      url: 'facebook.com',
      icon: Icons.facebook,
      color: Colors.blue,
    ),
    QuickAccessItem(
      title: 'GitHub',
      url: 'github.com',
      icon: Icons.code,
      color: Colors.grey,
    ),
    QuickAccessItem(
      title: 'Twitter',
      url: 'twitter.com',
      icon: Icons.alternate_email,
      color: Colors.lightBlue,
    ),
    QuickAccessItem(
      title: 'Reddit',
      url: 'reddit.com',
      icon: Icons.forum,
      color: Colors.orange,
    ),
    QuickAccessItem(
      title: 'Wikipedia',
      url: 'wikipedia.org',
      icon: Icons.menu_book,
      color: Colors.grey,
    ),
    QuickAccessItem(
      title: 'Amazon',
      url: 'amazon.com',
      icon: Icons.shopping_cart,
      color: Colors.orange,
    ),
  ];
}
