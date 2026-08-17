import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/router.dart';
import 'package:scanpdf/app/theme/app_theme.dart';
import 'package:scanpdf/core/constants/app_constants.dart';
import 'package:scanpdf/features/event/domain/deep_link_resolver.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';

class ScanPdfApp extends ConsumerStatefulWidget {
  const ScanPdfApp({super.key});

  @override
  ConsumerState<ScanPdfApp> createState() => _ScanPdfAppState();
}

class _ScanPdfAppState extends ConsumerState<ScanPdfApp> {
  late final GoRouter _router = buildRouter();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    // The purchase stream must be observed for the whole app lifetime.
    ref.read(plusProvider);
    _wireDeepLinks();
  }

  Future<void> _wireDeepLinks() async {
    // Cold start: the app was launched from the scanpdf:// link.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _openLink(initial);
    } catch (_) {
      // A malformed launch link must never block startup.
    }
    // Warm start: link arrives while the app is running.
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _openLink,
      onError: (Object _) {},
    );
  }

  void _openLink(Uri uri) {
    final route = resolveDeepLink(uri);
    if (uri.scheme == AppConstants.eventScheme &&
        uri.host == 'subscription-success') {
      ref.read(plusProvider.notifier).refreshEntitlement();
    }
    if (kDebugMode) {
      debugPrint('deep link received: $uri -> $route');
    }
    // Post-frame so cold-start navigation lands after the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router.go(route);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
      builder: (context, child) => ScrollConfiguration(
        behavior: const _BouncingScrollBehavior(),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _BouncingScrollBehavior extends ScrollBehavior {
  const _BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}
