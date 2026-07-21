import 'dart:typed_data';

import 'package:scanpdf/shared/models/scan_document.dart';

/// Library persistence: document metadata in Hive, page images on disk.
abstract class DocumentRepository {
  List<ScanDocument> getAll();

  ScanDocument? getById(String id);

  Future<void> upsert(ScanDocument document);

  /// Writes a page's processed + original images and returns nothing;
  /// files are addressed by the page id embedded in [ScanDocument.pages].
  Future<void> writePageFiles({
    required String pageId,
    required Uint8List processed,
    required Uint8List original,
  });

  /// Rewrites only the processed image (re-filter / re-crop / rotate).
  Future<void> rewriteProcessed({
    required String pageId,
    required Uint8List processed,
  });

  Future<Uint8List> readOriginal(String pageId);

  Future<void> moveToTrash(String id);

  Future<void> restore(String id);

  /// Deletes the document and every page file permanently.
  Future<void> deletePermanent(String id);

  Future<void> emptyTrash();
}
