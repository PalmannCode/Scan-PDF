import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:scanpdf/shared/models/scan_page.dart';

part 'scan_document.freezed.dart';
part 'scan_document.g.dart';

/// A document in the library: an ordered list of pages plus metadata.
/// Imported PDFs are rasterized into pages at import time so every
/// document shares the same page-image pipeline (edit, OCR, export).
@freezed
abstract class ScanDocument with _$ScanDocument {
  const ScanDocument._();

  const factory ScanDocument({
    required String id,
    required String title,
    String? folderId,
    required DateTime createdAt,
    required DateTime modifiedAt,
    @Default(<ScanPage>[]) List<ScanPage> pages,
    @Default(false) bool isDeleted,
    DateTime? deletedAt,

    /// True once text recognition has completed a clean pass, even if it
    /// found nothing. Distinguishes "no text on this page" from "not run
    /// yet", so the screen stops silently re-running Vision on every visit.
    @Default(false) bool ocrAttempted,
  }) = _ScanDocument;

  factory ScanDocument.fromJson(Map<String, dynamic> json) =>
      _$ScanDocumentFromJson(json);

  int get pageCount => pages.length;

  String get ocrText => pages
      .map((p) => p.ocrText.trim())
      .where((t) => t.isNotEmpty)
      .join('\n\n');

  bool get hasOcr => pages.any((p) => p.hasOcr);

  /// First page image drives the thumbnail.
  String? get thumbnailFileName =>
      pages.isEmpty ? null : pages.first.processedFileName;
}
