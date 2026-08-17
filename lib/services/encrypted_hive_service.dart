import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Opens the app's Hive boxes with AES encryption. The random key lives in
/// Keychain/Keystore, never alongside the box files or in source control.
abstract final class EncryptedHiveService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'scanpdf_hive_aes_key_v1';

  static Future<void> openBoxes(List<String> names) async {
    var encodedKey = await _storage.read(key: _keyName);
    final legacyValues = <String, Map<dynamic, String>>{};

    // Builds created before encrypted storage may already contain plaintext
    // boxes. Snapshot and rewrite them once, before persisting the new key.
    if (encodedKey == null) {
      for (final name in names) {
        if (!await Hive.boxExists(name)) continue;
        final legacy = await Hive.openBox<String>(name);
        legacyValues[name] = Map<dynamic, String>.from(legacy.toMap());
        await legacy.close();
        await Hive.deleteBoxFromDisk(name);
      }
      encodedKey = base64UrlEncode(Hive.generateSecureKey());
      await _storage.write(key: _keyName, value: encodedKey);
    }

    final key = base64Url.decode(encodedKey);
    if (key.length != 32) {
      throw StateError('The local encryption key is invalid.');
    }
    final cipher = HiveAesCipher(key);
    for (final name in names) {
      final box = await Hive.openBox<String>(name, encryptionCipher: cipher);
      final values = legacyValues[name];
      if (values != null && values.isNotEmpty) await box.putAll(values);
    }
  }
}
