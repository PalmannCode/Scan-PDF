import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:scanpdf/services/scanner_service.dart';
import 'package:scanpdf/shared/models/enums.dart';

void main() {
  group('ScannerService.normalizedCorners', () {
    test('keeps an ordered crop and clamps coordinates', () {
      expect(
        ScannerService.normalizedCorners(const [
          -0.1,
          0.1,
          0.9,
          0.0,
          1.1,
          0.9,
          0.1,
          1.2,
        ]),
        const [0.0, 0.1, 0.9, 0.0, 1.0, 0.9, 0.1, 1.0],
      );
    });

    test('rejects malformed or crossed crops', () {
      expect(ScannerService.normalizedCorners(const [0, 0]), isNull);
      expect(
        ScannerService.normalizedCorners(const [
          0.8,
          0.1,
          0.2,
          0.1,
          0.9,
          0.9,
          0.1,
          0.9,
        ]),
        isNull,
      );
      expect(
        ScannerService.normalizedCorners(const [
          0,
          0,
          double.nan,
          0,
          1,
          1,
          0,
          1,
        ]),
        isNull,
      );
    });
  });

  test('processing rotates and respects the maximum dimension', () async {
    final source = img.Image(width: 120, height: 60);
    img.fill(source, color: img.ColorRgb8(240, 235, 220));

    final output = await const ScannerService().process(
      ScanProcessRequest(
        bytes: Uint8List.fromList(img.encodeJpg(source)),
        filter: ScanFilter.original,
        rotationQuarters: 1,
        maxDimension: 80,
        quality: 90,
      ),
    );
    final decoded = img.decodeJpg(output);

    expect(decoded, isNotNull);
    expect(decoded!.width, 40);
    expect(decoded.height, 80);
  });
}
