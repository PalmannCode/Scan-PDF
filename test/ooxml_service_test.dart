import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scanpdf/services/ooxml_service.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/models/scan_page.dart';

void main() {
  late Directory temp;
  late ScanDocument document;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('scanpdf_ooxml_test_');
    await Directory('${temp.path}/pages').create(recursive: true);
    final page = img.Image(width: 80, height: 120)
      ..setPixelRgb(10, 10, 0, 0, 0);
    await File(
      '${temp.path}/pages/page-1.jpg',
    ).writeAsBytes(img.encodeJpg(page));
    document = ScanDocument(
      id: 'doc-1',
      title: 'Quarterly report & notes',
      createdAt: DateTime.utc(2026, 8, 17),
      modifiedAt: DateTime.utc(2026, 8, 17),
      pages: const [
        ScanPage(id: 'page-1', ocrText: 'Revenue <target> & actions'),
      ],
    );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('Word export is a valid OOXML archive with escaped document text', () {
    final bytes = OoxmlService(
      (relative) => '${temp.path}/$relative',
    ).buildDocx(document);
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((file) => file.name).toSet();
    expect(names, contains('[Content_Types].xml'));
    expect(names, contains('word/document.xml'));
    final xml = String.fromCharCodes(
      archive.files
          .singleWhere((file) => file.name == 'word/document.xml')
          .content,
    );
    expect(xml, contains('Revenue &lt;target&gt; &amp; actions'));
  });

  test(
    'PowerPoint export contains one slide and one embedded page image',
    () async {
      final bytes = await OoxmlService(
        (relative) => '${temp.path}/$relative',
      ).buildPptx(document);
      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.files.map((file) => file.name).toSet();
      expect(names, contains('ppt/slides/slide1.xml'));
      expect(names, contains('ppt/media/image1.jpg'));
      expect(names, contains('ppt/presentation.xml'));
    },
  );
}
