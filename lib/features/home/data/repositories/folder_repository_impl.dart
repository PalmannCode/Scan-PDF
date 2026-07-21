import 'dart:convert';

import 'package:hive/hive.dart';

import 'package:scanpdf/features/home/domain/repositories/folder_repository.dart';
import 'package:scanpdf/shared/models/scan_folder.dart';

class FolderRepositoryImpl implements FolderRepository {
  FolderRepositoryImpl({required this.box});

  final Box<String> box;

  @override
  List<ScanFolder> getAll() => box.values
      .map((raw) =>
          ScanFolder.fromJson(jsonDecode(raw) as Map<String, dynamic>))
      .toList();

  @override
  Future<void> upsert(ScanFolder folder) =>
      box.put(folder.id, jsonEncode(folder.toJson()));

  @override
  Future<void> delete(String id) => box.delete(id);
}
