import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:scanpdf/services/app_review_service.dart';
import 'package:scanpdf/services/export_service.dart';
import 'package:scanpdf/services/ocr_service.dart';
import 'package:scanpdf/services/pdf_service.dart';
import 'package:scanpdf/services/pdf_security_service.dart';
import 'package:scanpdf/services/scanner_service.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';

part 'storage_provider.g.dart';

abstract class HiveBoxes {
  static const String documents = 'documents';
  static const String folders = 'folders';
  static const String prefs = 'prefs';
}

/// Absolute app-documents directory — overridden in main() after
/// path_provider resolves it, so path lookup is synchronous app-wide.
@Riverpod(keepAlive: true)
String storageDir(Ref ref) => throw UnimplementedError('Overridden in main()');

/// Maps stored relative file names (`pages/<id>.jpg`) to absolute paths.
@Riverpod(keepAlive: true)
String Function(String) resolvePath(Ref ref) {
  final dir = ref.watch(storageDirProvider);
  return (relative) => '$dir/$relative';
}

@Riverpod(keepAlive: true)
Box<String> documentsBox(Ref ref) => Hive.box<String>(HiveBoxes.documents);

@Riverpod(keepAlive: true)
Box<String> foldersBox(Ref ref) => Hive.box<String>(HiveBoxes.folders);

@Riverpod(keepAlive: true)
Box<String> prefsBox(Ref ref) => Hive.box<String>(HiveBoxes.prefs);

@Riverpod(keepAlive: true)
ScannerService scannerService(Ref ref) => const ScannerService();

@Riverpod(keepAlive: true)
PdfService pdfService(Ref ref) => const PdfService();

@Riverpod(keepAlive: true)
ExportService exportService(Ref ref) => ExportService(
  pdfService: ref.watch(pdfServiceProvider),
  resolvePath: ref.watch(resolvePathProvider),
  analytics: ref.watch(analyticsServiceProvider),
  settings: ref.watch(settingsProvider),
  pdfSecurityService: const PdfSecurityService(),
);

@Riverpod(keepAlive: true)
OcrService ocrService(Ref ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
}

@Riverpod(keepAlive: true)
AppReviewService appReviewService(Ref ref) =>
    AppReviewService(ref.watch(prefsBoxProvider));
