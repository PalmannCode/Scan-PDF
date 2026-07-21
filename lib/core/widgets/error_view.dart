import 'package:flutter/material.dart';

import 'package:scanpdf/core/widgets/empty_state.dart';
import 'package:scanpdf/core/widgets/paper_sheet_illustration.dart';

/// Friendly illustrated error view with retry — no raw exception text.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.subtitle = 'The document tools hit a snag. Please try again.',
    this.onRetry,
    this.onShell = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  final bool onShell;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      illustration: PaperSheetIllustration(onShell: onShell, torn: true),
      title: title,
      subtitle: subtitle,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
      onShell: onShell,
    );
  }
}
