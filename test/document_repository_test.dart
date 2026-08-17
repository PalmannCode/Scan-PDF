import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:scanpdf/features/home/data/repositories/document_repository_impl.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/models/scan_page.dart';

void main() {
  late Directory temp;
  late Box<String> box;
  late DocumentRepositoryImpl repository;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('scanpdf_repository_test_');
    Hive.init(temp.path);
    box = await Hive.openBox<String>('documents');
    repository = DocumentRepositoryImpl(
      box: box,
      resolvePath: (relative) => '${temp.path}/files/$relative',
    );
  });

  tearDown(() async {
    await box.close();
    await temp.delete(recursive: true);
  });

  test('damaged metadata does not hide valid documents', () async {
    final now = DateTime(2026, 8, 17);
    final document = ScanDocument(
      id: 'valid',
      title: 'Warranty receipt',
      createdAt: now,
      modifiedAt: now,
      pages: const [ScanPage(id: 'page-1')],
    );
    await box.put('damaged', '{broken json');
    await box.put(document.id, jsonEncode(document.toJson()));

    expect(repository.getAll(), [document]);
    expect(repository.getById('damaged'), isNull);
  });

  test('permanent deletion removes metadata and both page files', () async {
    final now = DateTime(2026, 8, 17);
    final document = ScanDocument(
      id: 'document-1',
      title: 'Receipt',
      createdAt: now,
      modifiedAt: now,
      pages: const [ScanPage(id: 'page-1')],
    );
    await repository.writePageFiles(
      pageId: 'page-1',
      processed: Uint8List.fromList([1, 2, 3]),
      original: Uint8List.fromList([4, 5, 6]),
    );
    await repository.upsert(document);

    await repository.deletePermanent(document.id);

    expect(repository.getById(document.id), isNull);
    expect(File('${temp.path}/files/pages/page-1.jpg').existsSync(), isFalse);
    expect(
      File('${temp.path}/files/pages/page-1_orig.jpg').existsSync(),
      isFalse,
    );
  });
}
