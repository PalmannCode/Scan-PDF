import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';

/// Illustrated empty state — every list/grid screen gets one. The
/// illustration is a custom-painted scene passed by the caller.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.onShell = false,
  });

  final Widget illustration;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// True when shown on the dark indigo shell.
  final bool onShell;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titleColor = onShell ? colors.onShell : colors.textPrimary;
    final subColor = onShell ? colors.onShellMuted : colors.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration,
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.headline(titleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTypography.body(subColor),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PressableTap(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: AppShapes.buttonRadius,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTypography.bodyMedium(Colors.white),
                  ),
                ),
              ),
            ],
          ],
        )
            .animate()
            .fadeIn(duration: AppMotion.sheet, curve: AppMotion.enter)
            .moveY(
              begin: 8,
              end: 0,
              duration: AppMotion.sheet,
              curve: AppMotion.enter,
            ),
      ),
    );
  }
}
