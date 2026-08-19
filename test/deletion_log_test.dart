import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:scanpdf/features/home/data/repositories/document_repository_impl.dart';
import 'package:scanpdf/features/home/data/repositories/folder_repository_impl.dart';
import 'package:scanpdf/services/deletion_log.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/models/scan_folder.dart';
import 'package:scanpdf/shared/models/scan_page.dart';

void main() {
  late Directory temp;
  late Box<String> documentsBox;
  late Box<String> foldersBox;
  late Box<String> prefsBox;
  late DeletionLog log;
  late DocumentRepositoryImpl documents;
  late FolderRepositoryImpl folders;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('scanpdf_deletion_log_test_');
    Hive.init(temp.path);
    documentsBox = await Hive.openBox<String>('documents');
    foldersBox = await Hive.openBox<String>('folders');
    prefsBox = await Hive.openBox<String>('prefs');
    log = DeletionLog(prefsBox);
    documents = DocumentRepositoryImpl(
      box: documentsBox,
      resolvePath: (relative) => '${temp.path}/files/$relative',
      deletionLog: log,
    );
    folders = FolderRepositoryImpl(box: foldersBox, deletionLog: log);
  });

  tearDown(() async {
    await documentsBox.close();
    await foldersBox.close();
    await prefsBox.close();
    await temp.delete(recursive: true);
  });

  Future<ScanDocument> seedDocument(String id) async {
    final now = DateTime(2026, 8, 18);
    final document = ScanDocument(
      id: id,
      title: 'Receipt',
      createdAt: now,
      modifiedAt: now,
      pages: [ScanPage(id: '$id-page')],
    );
    await documents.writePageFiles(
      pageId: '$id-page',
      processed: Uint8List.fromList([1, 2, 3]),
      original: Uint8List.fromList([4, 5, 6]),
    );
    await documents.upsert(document);
    return document;
  }

  test('permanent deletion tombstones the document id', () async {
    final document = await seedDocument('doc-1');
    expect(log.documentIds, isEmpty);

    await documents.deletePermanent(document.id);

    // Without this the id is indistinguishable from a document this device
    // has never seen, and cloud sync restores it.
    expect(log.documentIds, contains('doc-1'));
  });

  test('emptying the trash tombstones every document it removes', () async {
    for (final id in ['doc-1', 'doc-2', 'doc-3']) {
      final document = await seedDocument(id);
      await documents.upsert(
        document.copyWith(isDeleted: true, deletedAt: DateTime(2026, 8, 18)),
      );
    }

    await documents.emptyTrash();

    expect(documents.getAll(), isEmpty);
    expect(log.documentIds, {'doc-1', 'doc-2', 'doc-3'});
  });

  test('deleting a document that does not exist records nothing', () async {
    await documents.deletePermanent('never-existed');
    expect(log.documentIds, isEmpty);
  });

  test('moving to trash does not tombstone — it is reversible', () async {
    final document = await seedDocument('doc-1');
    await documents.moveToTrash(document.id);
    expect(log.documentIds, isEmpty);
    await documents.restore(document.id);
    expect(documents.getById('doc-1')?.isDeleted, isFalse);
  });

  test('folder deletion tombstones the folder id', () async {
    final now = DateTime(2026, 8, 18);
    await folders.upsert(
      ScanFolder(
        id: 'folder-1',
        name: 'Invoices',
        createdAt: now,
        modifiedAt: now,
      ),
    );

    await folders.delete('folder-1');

    expect(log.folderIds, contains('folder-1'));
  });

  test('tombstones survive a reopen and clear only when purged', () async {
    await seedDocument('doc-1');
    await documents.deletePermanent('doc-1');

    final reopened = DeletionLog(prefsBox);
    expect(reopened.documentIds, contains('doc-1'));

    await reopened.clearDocuments(['doc-1']);
    expect(reopened.documentIds, isEmpty);
  });

  test(
    'a damaged tombstone list never resurrects deletions silently',
    () async {
      await prefsBox.put(DeletionLog.documentsKey, '{not a list');
      expect(log.documentIds, isEmpty);

      await seedDocument('doc-1');
      await documents.deletePermanent('doc-1');
      expect(log.documentIds, contains('doc-1'));
    },
  );
}
