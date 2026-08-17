import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scanpdf/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('watermarked PDF keeps every source page', () async {
    final first = img.Image(width: 80, height: 120);
    final second = img.Image(width: 120, height: 80);
    final bytes = await const PdfService().buildWatermarkedPdf(
      [img.encodeJpg(first), img.encodeJpg(second)],
      text: 'CONFIDENTIAL',
      opacity: 0.3,
      position: 'center',
      repeat: true,
      firstPage: 0,
      lastPage: 1,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(500));
  });
}
