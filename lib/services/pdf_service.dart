import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

/// PDF assembly and rasterization. Documents are page-image based, so a
/// PDF export embeds each page image at its own aspect ratio, and PDF
/// imports are rasterized back into page images.
class PdfService {
  const PdfService();

  /// Builds a PDF where each page matches its image's aspect ratio at
  /// A4 width.
  Future<Uint8List> buildPdf(
    List<Uint8List> pageImages, {
    List<String>? searchableText,
  }) async {
    final doc = pw.Document();
    pw.Font? ocrFont;
    if (searchableText?.any((text) => text.trim().isNotEmpty) ?? false) {
      ocrFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Archivo.ttf'));
    }
    for (var index = 0; index < pageImages.length; index++) {
      final bytes = pageImages[index];
      final image = pw.MemoryImage(bytes);
      final w = image.width;
      final h = image.height;
      final aspect = (w != null && h != null && w > 0)
          ? h / w
          : PdfPageFormat.a4.height / PdfPageFormat.a4.width;
      final format = PdfPageFormat(
        PdfPageFormat.a4.width,
        PdfPageFormat.a4.width * aspect,
      );
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            children: [
              pw.Positioned.fill(child: pw.Image(image, fit: pw.BoxFit.fill)),
              if (ocrFont != null &&
                  index < (searchableText?.length ?? 0) &&
                  searchableText![index].trim().isNotEmpty)
                pw.Positioned.fill(
                  child: pw.Opacity(
                    opacity: 0.01,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Text(
                        searchableText[index],
                        style: pw.TextStyle(font: ocrFont, fontSize: 8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return doc.save();
  }

  /// Builds a PDF with a visible text or image watermark on a selected page
  /// range. Watermarking happens only in the exported copy; source scans stay
  /// untouched.
  Future<Uint8List> buildWatermarkedPdf(
    List<Uint8List> pageImages, {
    required String text,
    Uint8List? watermarkImage,
    double opacity = 0.25,
    String position = 'center',
    bool repeat = false,
    int firstPage = 0,
    int? lastPage,
  }) async {
    final doc = pw.Document();
    final watermarkFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Archivo.ttf'),
    );
    final safeLast = (lastPage ?? pageImages.length - 1).clamp(
      0,
      pageImages.length - 1,
    );
    for (var index = 0; index < pageImages.length; index++) {
      final image = pw.MemoryImage(pageImages[index]);
      final w = image.width;
      final h = image.height;
      final aspect = (w != null && h != null && w > 0)
          ? h / w
          : PdfPageFormat.a4.height / PdfPageFormat.a4.width;
      final format = PdfPageFormat(
        PdfPageFormat.a4.width,
        PdfPageFormat.a4.width * aspect,
      );
      final applies = index >= firstPage && index <= safeLast;
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            children: [
              pw.Positioned.fill(child: pw.Image(image, fit: pw.BoxFit.fill)),
              if (applies)
                ..._watermarkWidgets(
                  format: format,
                  text: text,
                  image: watermarkImage == null
                      ? null
                      : pw.MemoryImage(watermarkImage),
                  opacity: opacity.clamp(0.05, 0.9),
                  position: position,
                  repeat: repeat,
                  font: watermarkFont,
                ),
            ],
          ),
        ),
      );
    }
    return doc.save();
  }

  List<pw.Widget> _watermarkWidgets({
    required PdfPageFormat format,
    required String text,
    required pw.MemoryImage? image,
    required double opacity,
    required String position,
    required bool repeat,
    required pw.Font font,
  }) {
    pw.Widget mark() => pw.Opacity(
      opacity: opacity,
      child: image != null
          ? pw.Image(image, width: format.width * 0.28, fit: pw.BoxFit.contain)
          : pw.Transform.rotate(
              angle: -0.45,
              child: pw.Text(
                text.trim().isEmpty ? 'CONFIDENTIAL' : text.trim(),
                style: pw.TextStyle(
                  color: PdfColors.grey700,
                  fontSize: 34,
                  font: font,
                ),
              ),
            ),
    );

    if (repeat) {
      return [
        for (final top in const [0.18, 0.48, 0.78])
          for (final left in const [0.2, 0.62])
            pw.Positioned(
              top: format.height * top,
              left: format.width * left - format.width * 0.2,
              child: mark(),
            ),
      ];
    }
    return [
      pw.Positioned.fill(
        child: pw.Align(
          alignment: switch (position) {
            'top' => pw.Alignment.topCenter,
            'bottom' => pw.Alignment.bottomCenter,
            _ => pw.Alignment.center,
          },
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(36),
            child: mark(),
          ),
        ),
      ),
    ];
  }

  /// Rasterizes an imported PDF into PNG page images (native renderer).
  Future<List<Uint8List>> rasterizePdf(
    Uint8List pdfBytes, {
    double dpi = 144,
  }) async {
    final pages = <Uint8List>[];
    await for (final raster in Printing.raster(pdfBytes, dpi: dpi)) {
      pages.add(await raster.toPng());
    }
    return pages;
  }
}
