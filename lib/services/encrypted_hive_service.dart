import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

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
      // Snapshot every legacy box before deleting anything, so a failure on
      // a later box never orphans an earlier one.
      for (final name in names) {
        if (!await Hive.boxExists(name)) continue;
        final Box<String> legacy;
        try {
          // A missing key with existing box files can also mean the boxes
          // are already encrypted but the keychain entry was lost (e.g. an
          // unencrypted backup restore). Without a cipher their checksums
          // fail, and Hive's default crash recovery would silently truncate
          // the file to zero bytes. Disable it and abort instead — never
          // destroy a box we cannot read.
          legacy = await Hive.openBox<String>(name, crashRecovery: false);
        } on HiveError catch (error) {
          throw StateError(
            'Legacy Hive box "$name" is not readable as plaintext ($error). '
            'Aborting migration; the box files were left untouched.',
          );
        }
        legacyValues[name] = Map<dynamic, String>.from(legacy.toMap());
        await legacy.close();
      }
      for (final entry in legacyValues.entries) {
        // An empty snapshot of a non-empty file means the data was not
        // captured; deleting it would be unrecoverable, so keep the file.
        if (entry.value.isEmpty && await _boxFileHasData(entry.key)) continue;
        await Hive.deleteBoxFromDisk(entry.key);
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

  /// True when a box's on-disk file exists and is non-empty. Boxes live
  /// directly in the app documents directory (`Hive.initFlutter()` with no
  /// subdirectory) as `<name>.hive` / `<name>.hivec`.
  static Future<bool> _boxFileHasData(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    for (final extension in const ['hive', 'hivec']) {
      final file = File('${dir.path}/${name.toLowerCase()}.$extension');
      if (await file.exists() && await file.length() > 0) return true;
    }
    return false;
  }
}
