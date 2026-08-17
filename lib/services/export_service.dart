import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:scanpdf/services/pdf_service.dart';
import 'package:scanpdf/services/pdf_security_service.dart';
import 'package:scanpdf/services/ooxml_service.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/models/scan_settings.dart';

/// Export pipeline (Jira §21): PDF, JPG/PNG per page, TXT from OCR —
/// written to a temp dir and handed to the system share sheet.
class ExportService {
  const ExportService({
    required this.pdfService,
    required this.resolvePath,
    required this.analytics,
    required this.settings,
    required this.pdfSecurityService,
  });

  final PdfService pdfService;
  final AnalyticsService analytics;
  final ScanSettings settings;
  final PdfSecurityService pdfSecurityService;

  /// Maps a stored relative file name to an absolute path.
  final String Function(String relative) resolvePath;

  Future<Directory> _exportDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/exports');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _safeName(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'Scan_PDF' : cleaned;
  }

  Future<File> buildPdfFile(ScanDocument document) async {
    final images = <Uint8List>[
      for (final page in document.pages)
        await File(resolvePath(page.processedFileName)).readAsBytes(),
    ];
    final bytes = await pdfService.buildPdf(
      images,
      searchableText: settings.createSearchablePdf
          ? [for (final page in document.pages) page.ocrText]
          : null,
    );
    final dir = await _exportDir();
    final file = File('${dir.path}/${_safeName(document.title)}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> sharePdf(ScanDocument document) async {
    await _tracked(document, 'pdf', () async {
      final file = await buildPdfFile(document);
      await SharePlus.instance.share(
        _shareParams(document, [XFile(file.path)]),
      );
    });
  }

  Future<File> buildCompressedPdfFile(
    ScanDocument document, {
    required String level,
  }) async {
    final maxDimension = switch (level) {
      'high' => 1000,
      'medium' => 1600,
      _ => 2200,
    };
    final quality = switch (level) {
      'high' => 55,
      'medium' => 70,
      _ => 84,
    };
    final images = <Uint8List>[];
    for (final page in document.pages) {
      final decoded = img.decodeImage(
        await File(resolvePath(page.processedFileName)).readAsBytes(),
      );
      if (decoded == null) continue;
      final longest = decoded.width > decoded.height
          ? decoded.width
          : decoded.height;
      final resized = longest > maxDimension
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxDimension : null,
              height: decoded.height > decoded.width ? maxDimension : null,
              interpolation: img.Interpolation.linear,
            )
          : decoded;
      images.add(img.encodeJpg(resized, quality: quality));
    }
    final bytes = await pdfService.buildPdf(
      images,
      searchableText: settings.createSearchablePdf
          ? [for (final page in document.pages) page.ocrText]
          : null,
    );
    final dir = await _exportDir();
    final file = File(
      '${dir.path}/${_safeName(document.title)}_${level}_compressed.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> shareCompressedPdf(
    ScanDocument document, {
    required String level,
  }) async {
    await _tracked(document, 'pdf_compressed_$level', () async {
      final file = await buildCompressedPdfFile(document, level: level);
      await SharePlus.instance.share(
        _shareParams(document, [XFile(file.path)]),
      );
    });
  }

  Future<void> shareWatermarkedPdf(
    ScanDocument document, {
    required String text,
    Uint8List? imageBytes,
    required double opacity,
    required String position,
    required bool repeat,
    required int firstPage,
    required int lastPage,
  }) async {
    await _tracked(document, 'pdf_watermarked', () async {
      final images = <Uint8List>[
        for (final page in document.pages)
          await File(resolvePath(page.processedFileName)).readAsBytes(),
      ];
      final bytes = await pdfService.buildWatermarkedPdf(
        images,
        text: text,
        watermarkImage: imageBytes,
        opacity: opacity,
        position: position,
        repeat: repeat,
        firstPage: firstPage,
        lastPage: lastPage,
      );
      final dir = await _exportDir();
      final file = File(
        '${dir.path}/${_safeName(document.title)}_watermarked.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        _shareParams(document, [XFile(file.path)]),
      );
    });
  }

  Future<void> shareLockedPdf(
    ScanDocument document, {
    required String password,
  }) async {
    await _tracked(document, 'pdf_locked', () async {
      final source = await buildPdfFile(document);
      final dir = await _exportDir();
      final output = '${dir.path}/${_safeName(document.title)}_locked.pdf';
      final protected = await pdfSecurityService.protect(
        source: source,
        password: password,
        outputPath: output,
      );
      await SharePlus.instance.share(
        _shareParams(document, [XFile(protected.path)]),
      );
    });
  }

  Future<void> shareImages(ScanDocument document, ExportFormat format) async {
    await _tracked(document, format.name, () async {
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
      await SharePlus.instance.share(_shareParams(document, files));
    });
  }

  Future<void> shareTxt(ScanDocument document) async {
    await _tracked(document, 'txt', () async {
      final dir = await _exportDir();
      final file = File('${dir.path}/${_safeName(document.title)}.txt');
      await file.writeAsString(document.ocrText, flush: true);
      await SharePlus.instance.share(
        _shareParams(document, [XFile(file.path)]),
      );
    });
  }

  Future<void> shareWord(ScanDocument document) async {
    await _tracked(document, 'docx', () async {
      final dir = await _exportDir();
      final file = File('${dir.path}/${_safeName(document.title)}.docx');
      await file.writeAsBytes(
        OoxmlService(resolvePath).buildDocx(document),
        flush: true,
      );
      await SharePlus.instance.share(
        _shareParams(document, [XFile(file.path)]),
      );
    });
  }

  Future<void> sharePowerPoint(ScanDocument document) async {
    await _tracked(document, 'pptx', () async {
      final dir = await _exportDir();
      final file = File('${dir.path}/${_safeName(document.title)}.pptx');
      await file.writeAsBytes(
        await OoxmlService(resolvePath).buildPptx(document),
        flush: true,
      );
      await SharePlus.instance.share(
        _shareParams(document, [XFile(file.path)]),
      );
    });
  }

  /// System print dialog with the assembled PDF (Jira §12 Utilities).
  Future<void> printDocument(ScanDocument document) async {
    final images = <Uint8List>[
      for (final page in document.pages)
        await File(resolvePath(page.processedFileName)).readAsBytes(),
    ];
    await Printing.layoutPdf(
      name: document.title,
      onLayout: (_) => pdfService.buildPdf(
        images,
        searchableText: settings.createSearchablePdf
            ? [for (final page in document.pages) page.ocrText]
            : null,
      ),
    );
  }

  Future<void> _tracked(
    ScanDocument document,
    String format,
    Future<void> Function() action,
  ) async {
    await analytics.track(
      'export_started',
      properties: {'document_id': document.id, 'export_format': format},
    );
    try {
      await action();
      await analytics.track(
        'export_completed',
        properties: {'document_id': document.id, 'export_format': format},
      );
      await analytics.track(
        'export_shared',
        properties: {'document_id': document.id, 'export_format': format},
      );
    } catch (error) {
      await analytics.track(
        'export_failed',
        properties: {
          'document_id': document.id,
          'export_format': format,
          'error_code': error.runtimeType.toString(),
        },
      );
      rethrow;
    }
  }

  ShareParams _shareParams(ScanDocument document, List<XFile> files) {
    final date = settings.includeDocumentDate
        ? DateFormat.yMMMd().format(document.createdAt)
        : '';
    String resolve(String template) => template
        .replaceAll('{title}', document.title)
        .replaceAll('{date}', date)
        .trim();
    final subject = resolve(settings.defaultEmailSubject);
    final body = [
      resolve(settings.defaultEmailBody),
      if (settings.defaultEmailSignature.trim().isNotEmpty)
        settings.defaultEmailSignature.trim(),
    ].where((part) => part.isNotEmpty).join('\n\n');
    return ShareParams(
      files: files,
      subject: subject.isEmpty ? document.title : subject,
      text: body.isEmpty ? null : body,
    );
  }
}
