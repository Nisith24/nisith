import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive storage service - replaces React Native AsyncStorage + MMKV
class HiveService {
  static late Box _generalBox;
  static late Box<List<String>> _listsBox;

  static const _generalBoxName = 'neetflow_general';
  static const _listsBoxName = 'neetflow_lists';
  static const _secureKeyName = 'neetflow_hive_key';

  /// Initialize Hive boxes with encryption
  static Future<void> init() async {
    // Ensure we have an encryption key
    final encryptionKey = await _getOrGenerateSecureKey();

    try {
      _generalBox = await Hive.openBox(
        _generalBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      _listsBox = await Hive.openBox<List<String>>(
        _listsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      // If opening failed, it might be due to a key mismatch or corruption.
      // In a real production app, we might want to recover by deleting the box.
      // For now, rethrow to fail visibly during development/testing.
      debugPrint('[HiveService] Failed to open encrypted boxes: $e');
      rethrow;
    }
  }

  /// specific helper to handle key generation and migration
  static Future<List<int>> _getOrGenerateSecureKey() async {
    const secureStorage = FlutterSecureStorage();

    // 1. Try to read existing key
    String? keyString;
    try {
      keyString = await secureStorage.read(key: _secureKeyName);
    } catch (e) {
      // On some platforms, reading might fail if storage is corrupted
      debugPrint('[HiveService] Failed to read secure key: $e');
    }

    if (keyString != null) {
      return base64Url.decode(keyString);
    }

    // 2. No key found - This is either a fresh install or an upgrade from unencrypted version.
    // Check if unencrypted data exists (Legacy Mode)
    final bool hasGeneral = await Hive.boxExists(_generalBoxName);
    final bool hasLists = await Hive.boxExists(_listsBoxName);

    if (hasGeneral || hasLists) {
      debugPrint('[HiveService] Detected legacy unencrypted data. Migrating...');
      return await _migrateToEncrypted(secureStorage);
    }

    // 3. Fresh install - Generate new key
    debugPrint('[HiveService] Fresh install. Generating new secure key.');
    final newKey = Hive.generateSecureKey();
    await secureStorage.write(
        key: _secureKeyName, value: base64Url.encode(newKey));
    return newKey;
  }

  /// Migrates data from unencrypted boxes to encrypted ones
  static Future<List<int>> _migrateToEncrypted(
      FlutterSecureStorage secureStorage) async {
    Map<dynamic, dynamic> generalData = {};
    Map<dynamic, List<String>> listsData = {};

    // 1. Read existing data
    try {
      if (await Hive.boxExists(_generalBoxName)) {
        final box = await Hive.openBox(_generalBoxName);
        generalData = Map.from(box.toMap());
        await box.close();
      }

      if (await Hive.boxExists(_listsBoxName)) {
        final box = await Hive.openBox<List<String>>(_listsBoxName);
        listsData = Map.from(box.toMap());
        await box.close();
      }
    } catch (e) {
      debugPrint(
          '[HiveService] Migration failed reading old data: $e. Starting fresh.');
      // If we can't read old data, we proceed to create new key anyway.
      // Data loss is unfortunate but better than app crash loop.
    }

    // 2. Delete old boxes
    try {
      await Hive.deleteBoxFromDisk(_generalBoxName);
      await Hive.deleteBoxFromDisk(_listsBoxName);
    } catch (e) {
      debugPrint('[HiveService] Failed to delete old boxes: $e');
    }

    // 3. Generate new key
    final newKey = Hive.generateSecureKey();
    await secureStorage.write(
        key: _secureKeyName, value: base64Url.encode(newKey));

    // 4. Write data to new encrypted boxes
    try {
      // Open with encryption
      final genBox = await Hive.openBox(
        _generalBoxName,
        encryptionCipher: HiveAesCipher(newKey),
      );
      if (generalData.isNotEmpty) {
        await genBox.putAll(generalData);
      }
      // We keep it open? No, init() will reopen it.
      await genBox.close();

      final listsBox = await Hive.openBox<List<String>>(
        _listsBoxName,
        encryptionCipher: HiveAesCipher(newKey),
      );
      if (listsData.isNotEmpty) {
        await listsBox.putAll(listsData);
      }
      await listsBox.close();

      debugPrint('[HiveService] Migration completed successfully.');
    } catch (e) {
      debugPrint('[HiveService] Migration failed writing new data: $e');
      // We still return the key so the app can continue (with empty boxes if write failed)
    }

    return newKey;
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
