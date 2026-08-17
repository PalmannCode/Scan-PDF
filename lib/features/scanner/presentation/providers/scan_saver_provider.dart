import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:scanpdf/features/event/presentation/providers/event_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_session_provider.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/services/scanner_service.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/models/scan_page.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

part 'scan_saver_provider.g.dart';

@Riverpod(keepAlive: true)
ScanSaver scanSaver(Ref ref) => ScanSaver(ref);

/// Persists the in-memory scan session as a library document: processes
/// every page off the UI isolate, writes page files, stores metadata,
/// counts engagement (review prompt), credits the event when eligible,
/// then OCRs in the background.
class ScanSaver {
  ScanSaver(this._ref);

  final Ref _ref;

  Future<ScanDocument> saveSession({
    required String title,
    String? folderId,
    void Function(int done, int total)? onProgress,
  }) async {
    final session = _ref.read(scanSessionProvider);
    if (session.pages.isEmpty) {
      throw StateError('Nothing captured');
    }
    final settings = _ref.read(settingsProvider);
    final scanner = _ref.read(scannerServiceProvider);
    final repo = _ref.read(documentRepositoryProvider);

    final pages = <ScanPage>[];
    final storedPageIds = <String>[];
    late final ScanDocument document;
    try {
      for (final captured in session.pages) {
        onProgress?.call(pages.length, session.pages.length);
        final original = await File(captured.tempPath).readAsBytes();
        final processed = await scanner.process(
          ScanProcessRequest(
            bytes: original,
            corners: captured.corners,
            filter: captured.filter,
            rotationQuarters: captured.rotationQuarters,
            quality: settings.imageQuality,
          ),
        );
        final pageId = const Uuid().v4();
        storedPageIds.add(pageId);
        await repo.writePageFiles(
          pageId: pageId,
          processed: processed,
          original: original,
        );
        pages.add(ScanPage(id: pageId, filter: captured.filter));
      }

      final now = DateTime.now();
      document = ScanDocument(
        id: const Uuid().v4(),
        title: title,
        folderId: folderId,
        createdAt: now,
        modifiedAt: now,
        pages: pages,
      );
      await repo.upsert(document);
    } catch (_) {
      for (final pageId in storedPageIds) {
        await repo.deletePageFiles(pageId);
      }
      rethrow;
    }
    _ref.read(documentsProvider.notifier).refresh();
    _ref.read(scanSessionProvider.notifier).clear();

    // Engagement counting — the review prompt fires only from here, after
    // a completed core action, never at launch (Guideline 5.6.3).
    try {
      final appState = _ref.read(appStateRepositoryProvider);
      final count = await appState.incrementSavedDocuments();
      await _ref.read(appReviewServiceProvider).maybeRequestReview(count);
    } catch (_) {
      // Ancillary review bookkeeping must not turn a completed save into an
      // error that encourages the user to create a duplicate document.
    }

    if (session.fromEvent) {
      try {
        await _ref
            .read(receiptRescueProvider.notifier)
            .recordRescue(document.id);
      } catch (_) {
        // Event progress is secondary to preserving the document itself.
      }
    }

    if (settings.autoOcrAfterScan) {
      // Fire-and-forget; search picks the text up when it lands.
      Future<void>.microtask(() => runOcr(document.id));
    }
    return document;
  }

  /// OCRs every page missing text and stores the result on the document.
  Future<void> runOcr(String documentId) async {
    final repo = _ref.read(documentRepositoryProvider);
    final resolve = _ref.read(resolvePathProvider);
    final ocr = _ref.read(ocrServiceProvider);
    final doc = repo.getById(documentId);
    if (doc == null) return;

    var changed = false;
    final updated = <ScanPage>[];
    for (final page in doc.pages) {
      if (page.hasOcr) {
        updated.add(page);
        continue;
      }
      try {
        final text = await ocr.recognizeFile(resolve(page.processedFileName));
        updated.add(page.copyWith(ocrText: text));
        changed = true;
      } catch (_) {
        updated.add(page);
      }
    }
    if (!changed) return;
    await repo.upsert(doc.copyWith(pages: updated));
    _ref.read(documentsProvider.notifier).refresh();
  }
}
