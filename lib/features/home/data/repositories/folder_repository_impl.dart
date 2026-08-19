import 'dart:convert';

import 'package:hive/hive.dart';

import 'package:scanpdf/features/home/domain/repositories/folder_repository.dart';
import 'package:scanpdf/services/deletion_log.dart';
import 'package:scanpdf/shared/models/scan_folder.dart';

class FolderRepositoryImpl implements FolderRepository {
  FolderRepositoryImpl({required this.box, this.deletionLog});

  final Box<String> box;

  /// Records deletions so cloud sync does not re-create the folder.
  final DeletionLog? deletionLog;

  @override
  List<ScanFolder> getAll() {
    final folders = <ScanFolder>[];
    for (final raw in box.values) {
      try {
        folders.add(
          ScanFolder.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        // Keep valid folders available if one stored entry is damaged.
      }
    }
    return folders;
  }

  @override
  Future<void> upsert(ScanFolder folder) =>
      box.put(folder.id, jsonEncode(folder.toJson()));

  @override
  Future<void> delete(String id) async {
    await box.delete(id);
    await deletionLog?.recordFolder(id);
  }
}
