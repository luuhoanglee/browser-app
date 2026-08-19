import 'dart:convert';
import 'dart:typed_data';
import 'package:browser_app/core/shared/cache/base_model_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:browser_app/core/logger/app_logger.dart';

class CacheManager<T> {
  static SharedPreferences? prefs;
  late String _keyData;
  String? _keyExpiration;

  static Future<void> init() async {
    prefs ??= await SharedPreferences.getInstance();
  }

  static T? getValue<T>(String key, {T Function(Map<String, dynamic>)? fromJson, List<T>? enumValues,}) {
    if (prefs == null) {
      AppLogger.warning('CacheManager', 'SharedPreferences not initialized — call CacheManager.init() first');
      return null;
    }
    // Check if the type T is supported and return the value accordingly
    if (T == String) {
      return prefs?.getString(key) as T?;
    } else if (T == int) {
      return prefs?.getInt(key) as T?;
    } else if (T == double) {
      return prefs?.getDouble(key) as T?;
    } else if (T == bool) {
      return prefs?.getBool(key) as T?;
    } else if (T == List<String>) {
      return prefs?.getStringList(key) as T?;
    } else if (T == Map<String, dynamic>) {
      String? jsonString = prefs?.getString(key.toString());
      return jsonString != null ? Map<String, dynamic>.from(json.decode(jsonString)) as T? : null;
    } else if (T == Uint8List) {
      final cacheData = prefs?.getString(key.toString());
      if (cacheData == null || cacheData.isEmpty) return null as T?;

      List<int> data = List.from(json.decode(cacheData));
      return data.isEmpty ? null : Uint8List.fromList(data) as T?;
    } else if (enumValues != null) {
      if (prefs?.getString(key.toString()) == null) return null as T?;

      return (enumValues.firstWhere(
              (e) => (e as Enum).name == prefs?.getString(key.toString()),
          orElse: () => enumValues.first)) as T?;
    } else if (fromJson != null) {
      String? jsonString = prefs?.getString(key);
      if (jsonString == null) return null;
      try {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        return fromJson(jsonMap);
      } catch (e) {
        AppLogger.error('CacheManager', 'Failed to parse JSON for key "$key"', error: e);
        return null;
      }
    }
    return null as T?; // Return null for unsupported types
  }

  CacheManager({required String keyData, bool isHasExpiration = false}) {
    _keyData = keyData;
    if (isHasExpiration) {
      _keyExpiration = '${keyData}_expirationTime';
    }
  }

  // Function to save data with an expiration date to SharedPreferences
  Future<bool> save(T data, [Duration? expirationDuration]) async {
    try {
      prefs ??= await SharedPreferences.getInstance();
      if (data is String) {
        await prefs!.setString(_keyData, data);
      } else if (data is int) {
        await prefs!.setInt(_keyData, data);
      } else if (data is double) {
        await prefs!.setDouble(_keyData, data);
      } else if (data is bool) {
        await prefs!.setBool(_keyData, data);
      } else if (data is List<String>) {
        await prefs!.setStringList(_keyData, data);
      } else if (data is Map<String, dynamic>) {
        await prefs!.setString(_keyData, jsonEncode(data)); // Convert Map to String
      } else if (data is BaseModelCache) {
        await prefs!.setString(_keyData, jsonEncode(data.toJson()));
      } else if (data is Enum) {
        await prefs!.setString(_keyData, data.name);
      } else if (data is Uint8List) {
        await prefs!.setString(_keyData, jsonEncode(data.toList()));
      } else {
        AppLogger.warning('CacheManager', 'Unsupported data type: ${data.runtimeType}');
        return false; // Unsupported type.
      }

      if (_keyExpiration != null) {
        DateTime expirationTime = DateTime.now().add(expirationDuration!);
        await prefs!.setString(_keyExpiration!, expirationTime.toIso8601String());
      }
      AppLogger.verbose('CacheManager', 'Saved: $_keyData');
      await prefs!.reload();
      return true;
    } catch (e, s) {
      AppLogger.error('CacheManager', 'Failed to save: $_keyData', error: e);
      return false;
    }
  }

  // Function to get data from SharedPreferences if it's not expired
  Future<T?> get({T Function(Map<String, dynamic>)? fromJson}) async {
    try {
      prefs ??= await SharedPreferences.getInstance();
      await prefs!.reload();
      T? data = getValue<T>(_keyData, fromJson: fromJson);

      if (_keyExpiration != null) {
        String? expirationTimeStr = prefs!.getString(_keyExpiration!);
        if (data == null || expirationTimeStr == null) {
          AppLogger.verbose('CacheManager', 'No data or expiration found for: $_keyData');
          return null; // No data or expiration time found.
        }

        DateTime expirationTime = DateTime.parse(expirationTimeStr);
        if (!expirationTime.isAfter(DateTime.now())) {
          // Data has expired. Remove it from SharedPreferences.
          await prefs!.remove(_keyData);
          await prefs!.remove(_keyExpiration!);
          AppLogger.verbose('CacheManager', 'Cache expired, removed: $_keyData');
          return null;
        }
      }

      AppLogger.verbose('CacheManager', 'Cache hit: $_keyData');
      // The data has not expired.
      return data;
    } catch (e) {
      AppLogger.error('CacheManager', 'Failed to retrieve: $_keyData', error: e);
      return null;
    }
  }

  // Function to clear data from SharedPreferences
  Future<void> clearData() async {
    try {
      prefs ??= await SharedPreferences.getInstance();
      await prefs!.remove(_keyData);
      if (_keyExpiration != null) {
        await prefs!.remove(_keyExpiration!);
      }
      AppLogger.verbose('CacheManager', 'Cleared: $_keyData');
    } catch (e) {
      AppLogger.error('CacheManager', 'Failed to clear: $_keyData', error: e);
    }
  }
}