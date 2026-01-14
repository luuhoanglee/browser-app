import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/tab_entity.dart';

class StorageService {
  static const String _tabsKey = 'cached_tabs';
  static const String _activeTabKey = 'active_tab_id';
  static const String _historyKey = 'browser_history';
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistorySize = 100; // Giới hạn 100 mục lịch sử

  // Debounce timers to avoid excessive disk writes
  static Timer? _tabsSaveDebounce;
  static Timer? _historySaveDebounce;
  static List<TabEntity>? _pendingTabs;
  static String? _pendingActiveTabId;
  static List<String>? _pendingHistory;

  // Rate limiting: track last save time to avoid too frequent writes
  static DateTime? _lastTabsSaveTime;
  static DateTime? _lastHistorySaveTime;
  static const Duration _minSaveInterval = Duration(seconds: 2); // Minimum 2s between saves

  // Save tabs to cache (debounced to avoid blocking UI)
  static Future<void> saveTabs(List<TabEntity> tabs, String? activeTabId) async {
    // Rate limiting: skip if saved recently (within 2 seconds)
    final now = DateTime.now();
    if (_lastTabsSaveTime != null &&
        now.difference(_lastTabsSaveTime!) < _minSaveInterval) {
      // Skip this save, a recent one is pending or completed
      return;
    }

    // Cancel previous pending save
    _tabsSaveDebounce?.cancel();

    // Store pending data
    _pendingTabs = tabs;
    _pendingActiveTabId = activeTabId;

    // Debounce: wait 2 seconds before actually saving to disk (increased from 500ms)
    _tabsSaveDebounce = Timer(const Duration(seconds: 2), () async {
      if (_pendingTabs == null) return;

      try {
        final prefs = await SharedPreferences.getInstance();

        // Convert tabs to JSON (off-main-thread via Timer)
        final List<Map<String, dynamic>> tabsJson = _pendingTabs!.map((tab) => {
          'id': tab.id,
          'url': tab.url,
          'title': tab.title,
          'index': tab.index,
          'isLoading': tab.isLoading,
          'thumbnail': tab.thumbnail != null ? base64Encode(tab.thumbnail!) : null,
        }).toList();

        await prefs.setString(_tabsKey, jsonEncode(tabsJson));

        if (_pendingActiveTabId != null) {
          await prefs.setString(_activeTabKey, _pendingActiveTabId!);
        }

        print('✅ Saved ${_pendingTabs!.length} tabs to cache');
        _pendingTabs = null;
        _pendingActiveTabId = null;
        _lastTabsSaveTime = DateTime.now();
      } catch (e) {
        print('❌ Error saving tabs: $e');
      }
    });
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

  // Save history to cache (debounced to avoid blocking UI)
  static Future<void> saveHistory(List<String> history) async {
    // Rate limiting: skip if saved recently (within 2 seconds)
    final now = DateTime.now();
    if (_lastHistorySaveTime != null &&
        now.difference(_lastHistorySaveTime!) < _minSaveInterval) {
      // Skip this save, a recent one is pending or completed
      return;
    }

    // Cancel previous pending save
    _historySaveDebounce?.cancel();

    // Store pending data
    _pendingHistory = history;

    // Debounce: wait 2 seconds before actually saving to disk (increased from 500ms)
    _historySaveDebounce = Timer(const Duration(seconds: 2), () async {
      if (_pendingHistory == null) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_historyKey, jsonEncode(_pendingHistory!));
        print('✅ Saved ${_pendingHistory!.length} history items to cache');
        _pendingHistory = null;
        _lastHistorySaveTime = DateTime.now();
      } catch (e) {
        print('❌ Error saving history: $e');
      }
    });
  }

  // Load history from cache
  static Future<List<String>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson == null) {
        print('No cached history found');
        return [];
      }

      final List<dynamic> decoded = jsonDecode(historyJson);
      final history = decoded.cast<String>();
      print('✅ Loaded ${history.length} history items from cache');
      return history;
    } catch (e) {
      print('❌ Error loading history: $e');
      return [];
    }
  }

  // Clear history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      print('✅ History cleared');
    } catch (e) {
      print('❌ Error clearing history: $e');
    }
  }

  // Save search history
  static Future<void> saveSearchHistory(List<String> searchHistory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_searchHistoryKey, jsonEncode(searchHistory));
      print('✅ Saved ${searchHistory.length} search history items');
    } catch (e) {
      print('❌ Error saving search history: $e');
    }
  }

  // Load search history
  static Future<List<String>> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchHistoryJson = prefs.getString(_searchHistoryKey);

      if (searchHistoryJson == null) {
        print('No cached search history found');
        return [];
      }

      final List<dynamic> decoded = jsonDecode(searchHistoryJson);
      final searchHistory = decoded.cast<String>();
      print('✅ Loaded ${searchHistory.length} search history items');
      return searchHistory;
    } catch (e) {
      print('❌ Error loading search history: $e');
      return [];
    }
  }

  // Clear search history
  static Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      print('✅ Search history cleared');
    } catch (e) {
      print('❌ Error clearing search history: $e');
    }
  }
}
