import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// PDF assembly and rasterization. Documents are page-image based, so a
/// PDF export embeds each page image at its own aspect ratio, and PDF
/// imports are rasterized back into page images.
class PdfService {
  const PdfService();

  /// Builds a PDF where each page matches its image's aspect ratio at
  /// A4 width.
  Future<Uint8List> buildPdf(List<Uint8List> pageImages) async {
    final doc = pw.Document();
    for (final bytes in pageImages) {
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
          build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );
    }
    return doc.save();
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
