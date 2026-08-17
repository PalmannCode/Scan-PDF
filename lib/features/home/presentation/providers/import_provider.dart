import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:scanpdf/features/scanner/presentation/providers/scan_session_provider.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

part 'import_provider.g.dart';

@Riverpod(keepAlive: true)
ImportController importController(Ref ref) => ImportController(ref);

/// Photo/file import (Jira §10 Photos, §11 Import Files): builds a scan
/// session from picked media so imports share the review/save pipeline.
/// Imported pages default to the Original filter — imports are not
/// auto-enhanced.
class ImportController {
  ImportController(this._ref);

  final Ref _ref;

  /// Returns the number of pages added (0 = user cancelled).
  Future<int> importPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return 0;
    final session = _ref.read(scanSessionProvider.notifier);
    session.start();
    for (final file in picked) {
      session.addCapture(file.path);
      _setOriginalFilter();
    }
    return picked.length;
  }

  /// Adds photos to the in-progress camera batch without resetting it.
  Future<int> importPhotosIntoCurrentSession() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return 0;
    final session = _ref.read(scanSessionProvider.notifier);
    for (final file in picked) {
      session.addCapture(file.path);
      _setOriginalFilter();
    }
    return picked.length;
  }

  /// PDF / image files via the system picker. PDFs are rasterized into
  /// page images so they join the same pipeline.
  Future<int> importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final paths =
        result?.files.map((f) => f.path).whereType<String>().toList() ?? [];
    if (paths.isEmpty) return 0;

    final session = _ref.read(scanSessionProvider.notifier);
    session.start();
    var added = 0;
    final tmp = await getTemporaryDirectory();
    for (final path in paths) {
      if (path.toLowerCase().endsWith('.pdf')) {
        final bytes = await File(path).readAsBytes();
        final pages = await _ref.read(pdfServiceProvider).rasterizePdf(bytes);
        for (final pageBytes in pages) {
          final tempPath = '${tmp.path}/import_${const Uuid().v4()}.png';
          await File(tempPath).writeAsBytes(pageBytes, flush: true);
          session.addCapture(tempPath);
          _setOriginalFilter();
          added++;
        }
      } else {
        session.addCapture(path);
        _setOriginalFilter();
        added++;
      }
    }
    return added;
  }

  void _setOriginalFilter() {
    final notifier = _ref.read(scanSessionProvider.notifier);
    final pages = _ref.read(scanSessionProvider).pages;
    final last = pages.length - 1;
    notifier.updatePage(
      last,
      pages[last].copyWith(filter: ScanFilter.original),
    );
  }
}
