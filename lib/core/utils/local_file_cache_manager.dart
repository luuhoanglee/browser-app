import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:satreps_client_app/core/shared/cache/cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple file cache manager that saves files locally by ID
/// and keeps track of them using SharedPreferences.
class LocalFileCacheManager {
  static const _key = 'cached_files_by_id';

  /// Save a PlatformFile to local app storage and associate it with a unique [id].
  /// Returns the saved [File] instance.
  static Future<File?> saveFile(String id, PlatformFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    final localFile = File('${dir.path}/${file.name}');

    // Copy or write the file contents into app directory
    if (file.path != null) {
      await File(file.path!).copy(localFile.path);
    } else if (file.bytes != null) {
      await localFile.writeAsBytes(file.bytes!);
    } else {
      return null;
    }

    // Save mapping: id -> local file path
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    final Map<String, String> map =
    jsonStr != null ? Map<String, String>.from(jsonDecode(jsonStr)) : {};

    map[id] = localFile.path;
    await prefs.setString(_key, jsonEncode(map));

    return localFile;
  }

  /// Retrieve a previously saved file by its [id].
  /// Returns null if not found or the file was deleted.
  static File? getFileById(String id) {
    final jsonStr = CacheManager.getValue<String>(_key);
    if (jsonStr == null) return null;

    final Map<String, String> map = Map<String, String>.from(jsonDecode(jsonStr));
    final path = map[id];
    if (path == null) return null;

    final file = File(path);
    if (file.existsSync()) {
      return file;
    } else {
      // If the file no longer exists, remove the record from preferences
      map.remove(id);
      CacheManager<String> manager = CacheManager(keyData: _key);
      manager.save(jsonEncode(map));
      return null;
    }
  }

  /// Remove a cached file by its [id].
  /// Deletes both the file from storage and the record in SharedPreferences.
  static Future<void> removeFileById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return;

    final Map<String, String> map = Map<String, String>.from(jsonDecode(jsonStr));
    final path = map[id];
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      map.remove(id);
      await prefs.setString(_key, jsonEncode(map));
    }
  }

  /// Clear all cached files and their records.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      final Map<String, String> map = Map<String, String>.from(jsonDecode(jsonStr));
      for (final path in map.values) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await prefs.remove(_key);
  }
}
