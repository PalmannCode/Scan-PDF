import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import 'package:scanpdf/features/home/domain/repositories/document_repository.dart';
import 'package:scanpdf/services/deletion_log.dart';
import 'package:scanpdf/shared/models/scan_document.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl({
    required this.box,
    required this.resolvePath,
    this.deletionLog,
  });

  final Box<String> box;
  final String Function(String relative) resolvePath;

  /// Records permanent deletions so cloud sync does not restore them.
  /// Null in local-only contexts (tests, guest use without a backend).
  final DeletionLog? deletionLog;

  @override
  List<ScanDocument> getAll() {
    final documents = <ScanDocument>[];
    for (final raw in box.values) {
      try {
        documents.add(
          ScanDocument.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        // One damaged index entry must not make the whole library unusable.
      }
    }
    return documents;
  }

  @override
  ScanDocument? getById(String id) {
    final raw = box.get(id);
    if (raw == null) return null;
    try {
      return ScanDocument.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
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
    await _pageFile(
      'pages/${pageId}_orig.jpg',
    ).writeAsBytes(original, flush: true);
  }

  @override
  Future<void> rewriteProcessed({
    required String pageId,
    required Uint8List processed,
  }) => _pageFile('pages/$pageId.jpg').writeAsBytes(processed, flush: true);

  @override
  Future<void> deletePageFiles(String pageId) async {
    for (final name in ['pages/$pageId.jpg', 'pages/${pageId}_orig.jpg']) {
      final file = File(resolvePath(name));
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<Uint8List> readOriginal(String pageId) =>
      _pageFile('pages/${pageId}_orig.jpg').readAsBytes();

  @override
  Future<void> moveToTrash(String id) async {
    final doc = getById(id);
    if (doc == null) return;
    await upsert(doc.copyWith(isDeleted: true, deletedAt: DateTime.now()));
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
      await deletePageFiles(page.id);
    }
    await box.delete(id);
    // Tombstone before the box write is observable, so a sync racing this
    // deletion cannot re-download the document it just lost locally.
    await deletionLog?.recordDocument(id);
  }

  @override
  Future<void> emptyTrash() async {
    final trashed = getAll()
        .where((d) => d.isDeleted)
        .map((d) => d.id)
        .toList();
    for (final id in trashed) {
      await deletePermanent(id);
    }
  }
}
