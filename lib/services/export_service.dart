import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:scanpdf/services/pdf_service.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/shared/models/scan_document.dart';

/// Export pipeline (Jira §21): PDF, JPG/PNG per page, TXT from OCR —
/// written to a temp dir and handed to the system share sheet.
class ExportService {
  const ExportService({required this.pdfService, required this.resolvePath});

  final PdfService pdfService;

  /// Maps a stored relative file name to an absolute path.
  final String Function(String relative) resolvePath;

  Future<Directory> _exportDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/exports');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _safeName(String title) =>
      title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim().replaceAll(' ', '_');

  Future<File> buildPdfFile(ScanDocument document) async {
    final images = <Uint8List>[
      for (final page in document.pages)
        await File(resolvePath(page.processedFileName)).readAsBytes(),
    ];
    final bytes = await pdfService.buildPdf(images);
    final dir = await _exportDir();
    final file = File('${dir.path}/${_safeName(document.title)}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> sharePdf(ScanDocument document) async {
    final file = await buildPdfFile(document);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: document.title),
    );
  }

  Future<void> shareImages(ScanDocument document, ExportFormat format) async {
    assert(format == ExportFormat.jpg || format == ExportFormat.png);
    final dir = await _exportDir();
    final files = <XFile>[];
    for (var i = 0; i < document.pages.length; i++) {
      final source = File(resolvePath(document.pages[i].processedFileName));
      final target =
          '${dir.path}/${_safeName(document.title)}_${i + 1}.${format.extension}';
      if (format == ExportFormat.jpg) {
        await source.copy(target);
      } else {
        final decoded = img.decodeImage(await source.readAsBytes());
        if (decoded == null) continue;
        await File(target).writeAsBytes(img.encodePng(decoded), flush: true);
      }
      files.add(XFile(target));
    }
    if (files.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(files: files, subject: document.title),
    );
  }

  Future<void> shareTxt(ScanDocument document) async {
    final dir = await _exportDir();
    final file = File('${dir.path}/${_safeName(document.title)}.txt');
    await file.writeAsString(document.ocrText, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: document.title),
    );
  }

  /// System print dialog with the assembled PDF (Jira §12 Utilities).
  Future<void> printDocument(ScanDocument document) async {
    final images = <Uint8List>[
      for (final page in document.pages)
        await File(resolvePath(page.processedFileName)).readAsBytes(),
    ];
    await Printing.layoutPdf(
      name: document.title,
      onLayout: (_) => pdfService.buildPdf(images),
    );
  }
}
