import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/tab_entity.dart';

class StorageService {
  static const String _tabsKey = 'cached_tabs';
  static const String _activeTabKey = 'active_tab_id';

  // Save tabs to cache
  static Future<void> saveTabs(List<TabEntity> tabs, String? activeTabId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert tabs to JSON
      final List<Map<String, dynamic>> tabsJson = tabs.map((tab) => {
        'id': tab.id,
        'url': tab.url,
        'title': tab.title,
        'index': tab.index,
        'isLoading': tab.isLoading,
        'thumbnail': tab.thumbnail != null ? base64Encode(tab.thumbnail!) : null,
      }).toList();

      await prefs.setString(_tabsKey, jsonEncode(tabsJson));

      if (activeTabId != null) {
        await prefs.setString(_activeTabKey, activeTabId);
      }

      print('✅ Saved ${tabs.length} tabs to cache');
    } catch (e) {
      print('❌ Error saving tabs: $e');
    }
  }

  // Load tabs from cache
  static Future<List<TabEntity>> loadTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tabsJson = prefs.getString(_tabsKey);

      if (tabsJson == null) {
        print('No cached tabs found');
        return [];
      }

      final List<dynamic> decoded = jsonDecode(tabsJson);
      final tabs = decoded.map((item) => TabEntity(
        id: item['id'],
        url: item['url'],
        title: item['title'],
        index: item['index'],
        isLoading: item['isLoading'] ?? false,
        thumbnail: item['thumbnail'] != null ? base64Decode(item['thumbnail']) : null,
      )).toList();

      print('✅ Loaded ${tabs.length} tabs from cache');
      return tabs;
    } catch (e) {
      print('❌ Error loading tabs: $e');
      return [];
    }
  }

  // Load active tab ID
  static Future<String?> loadActiveTabId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeTabKey);
    } catch (e) {
      print('❌ Error loading active tab ID: $e');
      return null;
    }
  }

  // Clear cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tabsKey);
      await prefs.remove(_activeTabKey);
      print('✅ Cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }
}
