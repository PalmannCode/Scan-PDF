import 'package:flutter_test/flutter_test.dart';

import 'package:scanpdf/core/utils/file_name_formats.dart';
import 'package:scanpdf/shared/models/scan_settings.dart';

void main() {
  final when = DateTime(2026, 8, 18, 8, 41);

  group('file name patterns', () {
    test('every shipped preset renders its literal word intact', () {
      expect(
        FileNameFormats.format(FileNameFormats.scan, when),
        'Scan 2026-08-18 08.41',
      );
      expect(
        FileNameFormats.format(FileNameFormats.document, when),
        'Document 20260818-0841',
      );
      expect(
        FileNameFormats.format(FileNameFormats.receipt, when),
        'Receipt 20260818',
      );
    });

    test('no preset leaks an ICU field into the literal word', () {
      // The original bug produced names like "00018AMn 2026-08-18 08.41" —
      // digits appearing inside what should be a plain word.
      for (final pattern in FileNameFormats.all) {
        final word = FileNameFormats.format(pattern, when).split(' ').first;
        expect(
          RegExp(r'^[A-Za-z]+$').hasMatch(word),
          isTrue,
          reason: 'literal word was parsed as date fields: "$word"',
        );
      }
    });

    test('legacy unquoted patterns are migrated, not re-rendered raw', () {
      expect(
        FileNameFormats.format('Scan yyyy-MM-dd HH.mm', when),
        'Scan 2026-08-18 08.41',
      );
      expect(
        FileNameFormats.format('Document yyyyMMdd-HHmm', when),
        'Document 20260818-0841',
      );
      expect(
        FileNameFormats.format('Receipt yyyyMMdd', when),
        'Receipt 20260818',
      );
    });

    test('normalize maps legacy values onto the shipped presets', () {
      expect(
        FileNameFormats.normalize('Receipt yyyyMMdd'),
        FileNameFormats.receipt,
      );
      // Already-migrated values are stable.
      expect(
        FileNameFormats.normalize(FileNameFormats.scan),
        FileNameFormats.scan,
      );
    });

    test('an unusable pattern falls back instead of throwing', () {
      expect(
        FileNameFormats.format("'unterminated", when),
        'Scan 2026-08-18 08.41',
      );
    });

    test('settings default is a quoted pattern', () {
      expect(const ScanSettings().defaultFileNameFormat, FileNameFormats.scan);
      expect(
        FileNameFormats.format(
          const ScanSettings().defaultFileNameFormat,
          when,
        ),
        'Scan 2026-08-18 08.41',
      );
    });
  });
}
