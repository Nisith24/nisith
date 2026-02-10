import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neetflow_flutter/core/storage/hive_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // Use a unique temp directory for each test
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  test('Fresh install creates encryption key and initializes storage', () async {
    // Act
    await HiveService.init();

    // Assert
    const storage = FlutterSecureStorage();
    final key = await storage.read(key: 'neetflow_hive_key');
    expect(key, isNotNull, reason: 'Encryption key should be generated');

    // Verify storage works
    await HiveService.setString('test_key', 'test_val');
    expect(HiveService.getString('test_key'), 'test_val');
  });

  test('Migration: Existing unencrypted data is preserved and encrypted', () async {
    // Arrange: Create unencrypted boxes with data
    // Note: Since we haven't run HiveService.init yet, these open without encryption
    // because Hive defaults to unencrypted if no cipher provided.
    final unencryptedGeneral = await Hive.openBox('neetflow_general');
    await unencryptedGeneral.put('legacy_key', 'legacy_val');
    await unencryptedGeneral.close();

    final unencryptedLists = await Hive.openBox<List<String>>('neetflow_lists');
    await unencryptedLists.put('legacy_list', ['a', 'b']);
    await unencryptedLists.close();

    // Verify no key exists initially
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'neetflow_hive_key'), isNull);

    // Act: Run init which triggers migration logic
    await HiveService.init();

    // Assert: Key created
    final key = await storage.read(key: 'neetflow_hive_key');
    expect(key, isNotNull, reason: 'Key should be created after migration');

    // Assert: Data preserved
    expect(HiveService.getString('legacy_key'), 'legacy_val');
    expect(HiveService.getStringList('legacy_list'), ['a', 'b']);

    // Assert: Verify it's actually encrypted by trying to open without key
    // We expect this to FAIL or return an empty/corrupted box (not the original data)
    await Hive.close(); // Close HiveService boxes to release lock

    // Attempt to open as unencrypted
    // Hive might treat encrypted file as corrupted and "recover" (wipe) it,
    // or just fail to read the data. In any case, we shouldn't see the data.
    final box = await Hive.openBox('neetflow_general');
    expect(box.get('legacy_key'), isNull, reason: 'Should not be able to read encrypted data without key');
  });
}
