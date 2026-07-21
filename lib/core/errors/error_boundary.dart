import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:scanpdf/core/errors/error_widgets.dart';

/// Global error wiring: replaces red screens with the friendly view and
/// swallows uncaught platform errors so users never see raw exceptions.
abstract class ErrorBoundary {
  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrintStack(stackTrace: details.stack);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught platform error: $error');
        debugPrintStack(stackTrace: stack);
      }
      return true;
    };
    ErrorWidget.builder = (details) => const FriendlyErrorWidget();
  }
}
