import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:scanpdf/features/home/data/repositories/document_repository_impl.dart';
import 'package:scanpdf/features/home/domain/repositories/document_repository.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';
import 'package:scanpdf/services/analytics_service.dart';

part 'documents_provider.g.dart';

@Riverpod(keepAlive: true)
DocumentRepository documentRepository(Ref ref) => DocumentRepositoryImpl(
  box: ref.watch(documentsBoxProvider),
  resolvePath: ref.watch(resolvePathProvider),
  deletionLog: ref.watch(deletionLogProvider),
);

/// Whole library (including trash); screens slice it via the computed
/// providers below.
@Riverpod(keepAlive: true)
class Documents extends _$Documents {
  DocumentRepository get _repo => ref.read(documentRepositoryProvider);

  @override
  List<ScanDocument> build() => _repo.getAll();

  void refresh() => state = _repo.getAll();

  Future<void> upsert(ScanDocument document) async {
    await _repo.upsert(document);
    refresh();
  }

  Future<void> rename(String id, String title) async {
    final doc = _repo.getById(id);
    if (doc == null) return;
    await _repo.upsert(doc.copyWith(title: title, modifiedAt: DateTime.now()));
    refresh();
    await ref
        .read(analyticsServiceProvider)
        .track('document_renamed', properties: {'document_id': id});
  }

  Future<void> moveToFolder(String id, String? folderId) async {
    final doc = _repo.getById(id);
    if (doc == null) return;
    await _repo.upsert(
      doc.copyWith(folderId: folderId, modifiedAt: DateTime.now()),
    );
    refresh();
    await ref
        .read(analyticsServiceProvider)
        .track(
          'document_moved',
          properties: {'document_id': id, 'folder_id': folderId},
        );
  }

  Future<void> updateOcrText({
    required String documentId,
    required String pageId,
    required String text,
  }) async {
    final doc = _repo.getById(documentId);
    if (doc == null || !doc.pages.any((page) => page.id == pageId)) return;

    final pages = [
      for (final page in doc.pages)
        if (page.id == pageId) page.copyWith(ocrText: text.trim()) else page,
    ];
    await _repo.upsert(doc.copyWith(pages: pages, modifiedAt: DateTime.now()));
    refresh();
    await ref
        .read(analyticsServiceProvider)
        .track(
          'ocr_text_edited',
          properties: {'document_id': documentId, 'page_id': pageId},
        );
  }

  Future<void> moveToTrash(String id) async {
    await _repo.moveToTrash(id);
    refresh();
    await ref
        .read(analyticsServiceProvider)
        .track(
          'document_deleted',
          properties: {'document_id': id, 'delete_type': 'trash'},
        );
  }

  Future<void> restore(String id) async {
    await _repo.restore(id);
    refresh();
    await ref
        .read(analyticsServiceProvider)
        .track('document_restored', properties: {'document_id': id});
  }

  Future<void> deletePermanent(String id) async {
    await _repo.deletePermanent(id);
    refresh();
    await ref
        .read(analyticsServiceProvider)
        .track(
          'document_deleted',
          properties: {'document_id': id, 'delete_type': 'permanent'},
        );
  }

  Future<void> emptyTrash() async {
    await _repo.emptyTrash();
    refresh();
  }

  /// Clears the folder reference from any document inside a deleted folder.
  Future<void> detachFolder(String folderId) async {
    for (final doc in state.where((d) => d.folderId == folderId)) {
      await _repo.upsert(doc.copyWith(folderId: null));
    }
    refresh();
  }
}

@riverpod
List<ScanDocument> activeDocuments(Ref ref) {
  final all = ref.watch(documentsProvider);
  return all.where((d) => !d.isDeleted).toList();
}

@riverpod
List<ScanDocument> trashedDocuments(Ref ref) {
  final all = ref.watch(documentsProvider);
  return all.where((d) => d.isDeleted).toList()..sort(
    (a, b) =>
        (b.deletedAt ?? b.modifiedAt).compareTo(a.deletedAt ?? a.modifiedAt),
  );
}

@riverpod
ScanDocument? documentById(Ref ref, String id) {
  final all = ref.watch(documentsProvider);
  for (final doc in all) {
    if (doc.id == id) return doc;
  }
  return null;
}

/// Documents shown in a library view, sorted per settings, optionally
/// scoped to a folder (null folderId = library root).
List<ScanDocument> sortDocuments(
  List<ScanDocument> docs,
  LibrarySortMode mode,
) {
  final sorted = [...docs];
  switch (mode) {
    case LibrarySortMode.dateCreated:
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case LibrarySortMode.dateModified:
      sorted.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    case LibrarySortMode.name:
      sorted.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
  }
  return sorted;
}
