import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/app/app.dart';
import 'package:scanpdf/config/app_config.dart';
import 'package:scanpdf/core/errors/error_boundary.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/services/encrypted_hive_service.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorBoundary.install();
  _registerFontLicenses();

  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      BackendRuntime.supabaseReady = true;
    } catch (error, stack) {
      BackendRuntime.supabaseError = error;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'supabase initialization',
        ),
      );
    }
  }
  await AnalyticsService.instance.initialize();

  final docsDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter();
  await EncryptedHiveService.openBoxes(const [
    HiveBoxes.documents,
    HiveBoxes.folders,
    HiveBoxes.prefs,
  ]);

  runApp(
    ProviderScope(
      overrides: [storageDirProvider.overrideWithValue(docsDir.path)],
      child: const ScanPdfApp(),
    ),
  );
}

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final archivo = await rootBundle.loadString('assets/fonts/Archivo-OFL.txt');
    yield LicenseEntryWithLineBreaks(<String>['Archivo'], archivo);
    final plex = await rootBundle.loadString(
      'assets/fonts/IBMPlexMono-OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['IBM Plex Mono'], plex);
  });
}
