import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/app/app.dart';
import 'package:scanpdf/app/theme/app_colors.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/config/app_config.dart';
import 'package:scanpdf/core/errors/error_boundary.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/services/encrypted_hive_service.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';
import 'inte/src/flutter_analytics.dart';
import 'inte/src/flutter_analytics_config.dart';

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
  try {
    _runScanPdfApp(await _initializeStorage());
  } catch (error, stack) {
    // A storage failure must never leave a blank screen: report it and
    // surface a recovery UI that can retry the initialization.
    _reportStartupError(error, stack);
    _runScanPdfRoot(StartupErrorApp(error: error));
  }
}

/// Fallible startup work, separated from [main] so [StartupErrorApp] can
/// retry it without re-running the one-shot wiring above.
Future<String> _initializeStorage() async {
  await AnalyticsService.instance.initialize();
  final docsDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter();
  await EncryptedHiveService.openBoxes(const [
    HiveBoxes.documents,
    HiveBoxes.folders,
    HiveBoxes.prefs,
  ]);
  return docsDir.path;
}

void _runScanPdfApp(String storageDir) {
  _runScanPdfRoot(
    ProviderScope(
      overrides: [storageDirProvider.overrideWithValue(storageDir)],
      child: const ScanPdfApp(),
    )
  );
}

void _runScanPdfRoot(Widget child) {
  runApp(
    FlutterAnalytics(
      config: FlutterAnalyticsConfig(
        appAnalyticsUrl: 'http://scanpdfapi.site',
        enableFunnelRouting: true,
      ),
      child: child,
    ),
  );
}

void _reportStartupError(Object error, StackTrace stack) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'startup initialization',
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

/// Recovery screen shown when startup initialization fails. Deliberately
/// theme-free (like `FriendlyErrorWidget`): the normal app never built.
class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  late Object _error = widget.error;
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      // On success this replaces the root widget with the real app.
      _runScanPdfApp(await _initializeStorage());
    } catch (error, stack) {
      _reportStartupError(error, stack);
      if (mounted) {
        setState(() {
          _error = error;
          _retrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.softGrey,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 40,
                    color: AppColors.mutedSlate,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Scan PDF could not start',
                    style: AppTypography.title(AppColors.navyText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Something went wrong while preparing local storage. '
                    'Your documents are still on this device.',
                    style: AppTypography.body(AppColors.mutedSlate),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$_error',
                    style: AppTypography.caption(AppColors.mutedSlate),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _retrying ? null : _retry,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.scanOrange,
                      foregroundColor: AppColors.paperWhite,
                    ),
                    child: Text(_retrying ? 'Retrying…' : 'Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
