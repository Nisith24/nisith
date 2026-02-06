import 'package:hive_flutter/hive_flutter.dart';

/// Hive storage service - replaces React Native AsyncStorage + MMKV
class HiveService {
  static late Box _generalBox;
  static late Box<List<String>> _listsBox;

  static const _generalBoxName = 'neetflow_general';
  static const _listsBoxName = 'neetflow_lists';

  /// Initialize Hive boxes
  static Future<void> init() async {
    _generalBox = await Hive.openBox(_generalBoxName);
    _listsBox = await Hive.openBox<List<String>>(_listsBoxName);
  }

  // --- String operations ---

  static String? getString(String key) {
    return _generalBox.get(key) as String?;
  }

  static Future<void> setString(String key, String value) async {
    await _generalBox.put(key, value);
  }

  static Future<void> removeString(String key) async {
    await _generalBox.delete(key);
  }

  // --- Int operations ---

  static int? getInt(String key) {
    return _generalBox.get(key) as int?;
  }

  static Future<void> setInt(String key, int value) async {
    await _generalBox.put(key, value);
  }

  // --- Bool operations ---

  static bool? getBool(String key) {
    return _generalBox.get(key) as bool?;
  }

  static Future<void> setBool(String key, bool value) async {
    await _generalBox.put(key, value);
  }

  // --- JSON operations ---

  static Map<String, dynamic>? getJson(String key) {
    final value = _generalBox.get(key);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static Future<void> setJson(String key, Map<String, dynamic> value) async {
    await _generalBox.put(key, value);
  }

  // --- List<String> operations ---

  static List<String> getStringList(String key) {
    return _listsBox.get(key) ?? [];
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await _listsBox.put(key, value);
  }

  static Future<void> addToStringList(String key, List<String> items) async {
    final current = getStringList(key);
    final merged = {...current, ...items}.toList();
    await setStringList(key, merged);
  }

  static Future<void> clearStringList(String key) async {
    await _listsBox.delete(key);
  }

  // --- Clear all ---

  static Future<void> clearAll() async {
    await _generalBox.clear();
    await _listsBox.clear();
  }
}

/// Storage keys for consistency
class StorageKeys {
  static const themeMode = 'theme_mode';
  static const pendingViewedMcqs = 'pending_viewed_mcqs';
  static const cachedUserProfile = 'cached_user_profile';
  static const authState = 'auth_state';
  static const lastSyncTime = 'last_sync_time';
  static const bookmarksData = 'bookmarks_data';
  static const isDarkMode = 'is_dark_mode';
}
