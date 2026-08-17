import 'package:flutter/material.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/signature/scan_pulse_frame.dart';

/// Compact ScanPulseFrame variant framing the library stats — the
/// signature motif living on the populated home screen. Numerals tick
/// up in Plex Mono on first build (brief: living details).
class LibraryStatsStrip extends StatelessWidget {
  const LibraryStatsStrip({
    super.key,
    required this.documentCount,
    required this.pageCount,
  });

  final int documentCount;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: ScanPulseFrame(
        animated: false,
        showTicks: false,
        strokeWidth: 2,
        inset: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TickingCount(value: documentCount),
              Text(
                ' documents · ',
                style: AppTypography.mono(colors.onShellMuted, size: 12),
              ),
              _TickingCount(value: pageCount),
              Text(
                ' pages',
                style: AppTypography.mono(colors.onShellMuted, size: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TickingCount extends StatelessWidget {
  const _TickingCount({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: AppMotion.sheet * 2,
      curve: AppMotion.enter,
      builder: (context, count, _) =>
          Text('$count', style: AppTypography.mono(colors.onShell, size: 12)),
    );
  }
}
