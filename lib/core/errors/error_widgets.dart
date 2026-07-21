import 'package:flutter/material.dart';

import 'package:scanpdf/app/theme/app_colors.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';

/// Replacement for the framework's error widget. Deliberately theme-free:
/// it can render before/without an inherited Theme.
class FriendlyErrorWidget extends StatelessWidget {
  const FriendlyErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.softGrey,
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
                'This part of the page had a problem',
                style: AppTypography.bodyMedium(AppColors.navyText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
