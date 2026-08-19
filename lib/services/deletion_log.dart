import 'dart:convert';

import 'package:hive/hive.dart';

/// Records ids the user deleted permanently on this device.
///
/// Cloud sync restores any remote row that is missing locally, so without a
/// tombstone a permanently deleted document is indistinguishable from one this
/// device has simply never seen — and comes straight back on the next sync.
/// Entries are cleared once the remote copy is actually gone.
class DeletionLog {
  const DeletionLog(this._box);

  final Box<String> _box;

  static const String documentsKey = 'deleted_document_ids';
  static const String foldersKey = 'deleted_folder_ids';

  Set<String> get documentIds => _read(documentsKey);

  Set<String> get folderIds => _read(foldersKey);

  Future<void> recordDocument(String id) => _add(documentsKey, id);

  Future<void> recordFolder(String id) => _add(foldersKey, id);

  Future<void> clearDocuments(Iterable<String> ids) =>
      _remove(documentsKey, ids);

  Future<void> clearFolders(Iterable<String> ids) => _remove(foldersKey, ids);

  Set<String> _read(String key) {
    final raw = _box.get(key);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
    } catch (_) {
      // A damaged tombstone list must never resurrect deleted documents,
      // but it also must not crash the library: start clean.
      return <String>{};
    }
  }

  Future<void> _write(String key, Set<String> ids) =>
      _box.put(key, jsonEncode(ids.toList()));

  Future<void> _add(String key, String id) async {
    final ids = _read(key);
    if (!ids.add(id)) return;
    await _write(key, ids);
  }

  Future<void> _remove(String key, Iterable<String> ids) async {
    final current = _read(key);
    final before = current.length;
    current.removeAll(ids.toSet());
    if (current.length == before) return;
    await _write(key, current);
  }
}
