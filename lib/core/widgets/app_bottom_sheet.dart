import 'package:flutter/material.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';

/// Rounded 28px paper sheet over the dark shell — the app's modal container.
abstract class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool scrollable = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = context.colors;
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.hairline,
                  borderRadius: AppShapes.pillRadius,
                ),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.headline(colors.textPrimary),
                      ),
                    ),
                    PressableTap(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.toolCard,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colors.textSecondary,
                          semanticLabel: 'Close',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(bottom: context.viewInsets.bottom),
                child: scrollable
                    ? SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: child,
                      )
                    : child,
              ),
            ),
          ],
        );
        return Container(
          constraints: BoxConstraints(
            maxHeight: context.screenSize.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: colors.paperCard,
            borderRadius: AppShapes.sheetRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        );
      },
    );
  }
}
