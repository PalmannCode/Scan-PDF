import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:scanpdf/app/app.dart';
import 'package:scanpdf/core/errors/error_boundary.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorBoundary.install();

  final docsDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter();
  await Hive.openBox<String>(HiveBoxes.documents);
  await Hive.openBox<String>(HiveBoxes.folders);
  await Hive.openBox<String>(HiveBoxes.prefs);

  runApp(
    ProviderScope(
      overrides: [
        storageDirProvider.overrideWithValue(docsDir.path),
      ],
      child: const ScanPdfApp(),
    ),
  );
}
