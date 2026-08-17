import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/viewer/data/signature_store.dart';
import 'package:scanpdf/services/scanner_service.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/models/scan_page.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

part 'viewer_actions_provider.g.dart';

@Riverpod(keepAlive: true)
SignatureStore signatureStore(Ref ref) => SignatureStore(
  prefs: ref.watch(prefsBoxProvider),
  resolvePath: ref.watch(resolvePathProvider),
);

@Riverpod(keepAlive: true)
ViewerActions viewerActions(Ref ref) => ViewerActions(ref);

class _SignBakeRequest {
  const _SignBakeRequest({
    required this.pageBytes,
    required this.signaturePng,
    required this.centerX,
    required this.centerY,
    required this.widthFraction,
  });

  final Uint8List pageBytes;
  final Uint8List signaturePng;
  final double centerX;
  final double centerY;
  final double widthFraction;
}

Uint8List _bakeSignatureSync(_SignBakeRequest request) {
  final page = img.decodeImage(request.pageBytes);
  final signature = img.decodeImage(request.signaturePng);
  if (page == null || signature == null) {
    throw const FormatException('Could not decode images');
  }
  final targetW = (page.width * request.widthFraction).round().clamp(
    24,
    page.width,
  );
  final scale = targetW / signature.width;
  final resized = img.copyResize(
    signature,
    width: targetW,
    height: (signature.height * scale).round(),
    interpolation: img.Interpolation.linear,
  );
  final dstX = (page.width * request.centerX - resized.width / 2).round();
  final dstY = (page.height * request.centerY - resized.height / 2).round();
  img.compositeImage(page, resized, dstX: dstX, dstY: dstY);
  return img.encodeJpg(page, quality: 90);
}

/// Document-level operations used by the viewer: merge and signing.
class ViewerActions {
  ViewerActions(this._ref);

  final Ref _ref;

  /// Copies a page's files under a fresh id so merged documents never
  /// share files with their sources (deleting one must not break the
  /// other).
  Future<ScanPage> _copyPage(ScanPage page) async {
    final resolve = _ref.read(resolvePathProvider);
    final repo = _ref.read(documentRepositoryProvider);
    final processed = await File(resolve(page.processedFileName)).readAsBytes();
    Uint8List original;
    try {
      original = await File(resolve(page.originalFileName)).readAsBytes();
    } catch (_) {
      original = processed;
    }
    final newId = const Uuid().v4();
    try {
      await repo.writePageFiles(
        pageId: newId,
        processed: processed,
        original: original,
      );
    } catch (_) {
      await repo.deletePageFiles(newId);
      rethrow;
    }
    return ScanPage(id: newId, filter: page.filter, ocrText: page.ocrText);
  }

  /// Merge Files (Jira §12 Edit): combines two documents into a NEW one.
  Future<ScanDocument> merge(ScanDocument first, ScanDocument second) async {
    final repo = _ref.read(documentRepositoryProvider);
    final pages = <ScanPage>[];
    try {
      for (final page in first.pages) {
        pages.add(await _copyPage(page));
      }
      for (final page in second.pages) {
        pages.add(await _copyPage(page));
      }
      final now = DateTime.now();
      final merged = ScanDocument(
        id: const Uuid().v4(),
        title: 'Merged ${DateFormat('yyyy-MM-dd HH.mm').format(now)}',
        createdAt: now,
        modifiedAt: now,
        pages: pages,
      );
      await repo.upsert(merged);
      _ref.read(documentsProvider.notifier).refresh();
      return merged;
    } catch (_) {
      for (final page in pages) {
        await repo.deletePageFiles(page.id);
      }
      rethrow;
    }
  }

  /// Creates a new independent document from selected source pages.
  Future<ScanDocument> extractPages(
    ScanDocument source,
    Iterable<int> pageIndices,
  ) async {
    final repo = _ref.read(documentRepositoryProvider);
    final indices = pageIndices.toSet().toList()..sort();
    if (indices.isEmpty ||
        indices.any((index) => index < 0 || index >= source.pageCount)) {
      throw ArgumentError('Select at least one valid page.');
    }
    final pages = <ScanPage>[];
    try {
      for (final index in indices) {
        pages.add(await _copyPage(source.pages[index]));
      }
      final now = DateTime.now();
      final extracted = ScanDocument(
        id: const Uuid().v4(),
        title: '${source.title} — Extracted',
        folderId: source.folderId,
        createdAt: now,
        modifiedAt: now,
        pages: pages,
      );
      await repo.upsert(extracted);
      _ref.read(documentsProvider.notifier).refresh();
      return extracted;
    } catch (_) {
      for (final page in pages) {
        await repo.deletePageFiles(page.id);
      }
      rethrow;
    }
  }

  Future<ScanDocument> duplicate(ScanDocument source) async {
    final copy = await extractPages(
      source,
      List<int>.generate(source.pageCount, (index) => index),
    );
    final renamed = copy.copyWith(title: '${source.title} — Copy');
    await _ref.read(documentRepositoryProvider).upsert(renamed);
    _ref.read(documentsProvider.notifier).refresh();
    return renamed;
  }

  Future<void> reorderPages(ScanDocument document, int from, int to) async {
    if (from < 0 || from >= document.pageCount) return;
    final pages = [...document.pages];
    final page = pages.removeAt(from);
    pages.insert(to.clamp(0, pages.length), page);
    await _ref
        .read(documentRepositoryProvider)
        .upsert(document.copyWith(pages: pages, modifiedAt: DateTime.now()));
    _ref.read(documentsProvider.notifier).refresh();
  }

  Future<void> deletePage(ScanDocument document, int index) async {
    if (document.pageCount <= 1) {
      throw StateError('A document must keep at least one page.');
    }
    if (index < 0 || index >= document.pageCount) return;
    final page = document.pages[index];
    final pages = [...document.pages]..removeAt(index);
    final repo = _ref.read(documentRepositoryProvider);
    await repo.upsert(
      document.copyWith(pages: pages, modifiedAt: DateTime.now()),
    );
    await repo.deletePageFiles(page.id);
    _ref.read(documentsProvider.notifier).refresh();
  }

  Future<void> appendImagePages(
    ScanDocument document,
    Iterable<String> imagePaths,
  ) async {
    final repo = _ref.read(documentRepositoryProvider);
    final pages = [...document.pages];
    final created = <ScanPage>[];
    try {
      for (final path in imagePaths) {
        final processed = await _ref
            .read(scannerServiceProvider)
            .process(
              ScanProcessRequest(
                bytes: await File(path).readAsBytes(),
                filter: ScanFilter.original,
              ),
            );
        final id = const Uuid().v4();
        await repo.writePageFiles(
          pageId: id,
          processed: processed,
          original: processed,
        );
        final page = ScanPage(id: id, filter: ScanFilter.original);
        pages.add(page);
        created.add(page);
      }
      await repo.upsert(
        document.copyWith(pages: pages, modifiedAt: DateTime.now()),
      );
      _ref.read(documentsProvider.notifier).refresh();
    } catch (_) {
      for (final page in created) {
        await repo.deletePageFiles(page.id);
      }
      rethrow;
    }
  }

  /// Bakes a signature into one page image at a normalized position.
  Future<void> applySignature({
    required ScanDocument document,
    required Iterable<int> pageIndices,
    required Uint8List signaturePng,
    required double centerX,
    required double centerY,
    required double widthFraction,
  }) async {
    final repo = _ref.read(documentRepositoryProvider);
    final resolve = _ref.read(resolvePathProvider);
    final indices = pageIndices.toSet().toList()..sort();
    if (indices.isEmpty ||
        indices.any((index) => index < 0 || index >= document.pageCount)) {
      throw ArgumentError('Select at least one valid page.');
    }
    for (final pageIndex in indices) {
      final page = document.pages[pageIndex];
      final pageBytes = await File(
        resolve(page.processedFileName),
      ).readAsBytes();
      final baked = await compute(
        _bakeSignatureSync,
        _SignBakeRequest(
          pageBytes: pageBytes,
          signaturePng: signaturePng,
          centerX: centerX,
          centerY: centerY,
          widthFraction: widthFraction,
        ),
      );
      await repo.rewriteProcessed(pageId: page.id, processed: baked);
      FileImage(File(resolve(page.processedFileName))).evict();
    }
    await repo.upsert(document.copyWith(modifiedAt: DateTime.now()));
    _ref.read(documentsProvider.notifier).refresh();
  }
}
