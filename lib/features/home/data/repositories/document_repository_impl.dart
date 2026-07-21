import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import 'package:scanpdf/features/home/domain/repositories/document_repository.dart';
import 'package:scanpdf/shared/models/scan_document.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl({required this.box, required this.resolvePath});

  final Box<String> box;
  final String Function(String relative) resolvePath;

  @override
  List<ScanDocument> getAll() => box.values
      .map((raw) => ScanDocument.fromJson(
          jsonDecode(raw) as Map<String, dynamic>))
      .toList();

  @override
  ScanDocument? getById(String id) {
    final raw = box.get(id);
    if (raw == null) return null;
    return ScanDocument.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> upsert(ScanDocument document) =>
      box.put(document.id, jsonEncode(document.toJson()));

  File _pageFile(String relative) {
    final file = File(resolvePath(relative));
    file.parent.createSync(recursive: true);
    return file;
  }

  @override
  Future<void> writePageFiles({
    required String pageId,
    required Uint8List processed,
    required Uint8List original,
  }) async {
    await _pageFile('pages/$pageId.jpg').writeAsBytes(processed, flush: true);
    await _pageFile('pages/${pageId}_orig.jpg')
        .writeAsBytes(original, flush: true);
  }

  @override
  Future<void> rewriteProcessed({
    required String pageId,
    required Uint8List processed,
  }) =>
      _pageFile('pages/$pageId.jpg').writeAsBytes(processed, flush: true);

  @override
  Future<Uint8List> readOriginal(String pageId) =>
      _pageFile('pages/${pageId}_orig.jpg').readAsBytes();

  @override
  Future<void> moveToTrash(String id) async {
    final doc = getById(id);
    if (doc == null) return;
    await upsert(
      doc.copyWith(isDeleted: true, deletedAt: DateTime.now()),
    );
  }

  @override
  Future<void> restore(String id) async {
    final doc = getById(id);
    if (doc == null) return;
    await upsert(doc.copyWith(isDeleted: false, deletedAt: null));
  }

  @override
  Future<void> deletePermanent(String id) async {
    final doc = getById(id);
    if (doc == null) return;
    for (final page in doc.pages) {
      for (final name in [page.processedFileName, page.originalFileName]) {
        final file = File(resolvePath(name));
        if (file.existsSync()) file.deleteSync();
      }
    }
    await box.delete(id);
  }

  @override
  Future<void> emptyTrash() async {
    final trashed =
        getAll().where((d) => d.isDeleted).map((d) => d.id).toList();
    for (final id in trashed) {
      await deletePermanent(id);
    }
  }
}
