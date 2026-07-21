import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/constants/app_constants.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/app_surface.dart';
import 'package:scanpdf/features/event/domain/event_phase.dart';
import 'package:scanpdf/features/event/presentation/providers/event_provider.dart';

/// Phase-aware home entry point for the Receipt Rescue Challenge.
/// Hidden once the event has ended.
class EventBanner extends ConsumerWidget {
  const EventBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = currentEventPhase();
    if (phase == EventPhase.ended) return const SizedBox.shrink();

    final colors = context.colors;
    final progress = ref.watch(receiptRescueProvider);
    final subtitle = switch (phase) {
      EventPhase.upcoming =>
        'Starts ${DateFormat.MMMd().format(AppConstants.eventStart)} — get ready',
      EventPhase.live =>
        '${progress.rescuedCount} / ${AppConstants.eventGoal} receipts rescued',
      EventPhase.ended => '',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: AppSurface(
        variant: SurfaceVariant.shell,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () => context.push('/event'),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.16),
                borderRadius: AppShapes.thumbnailRadius,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: colors.accent,
                size: 22,
                semanticLabel: 'Receipt Rescue Challenge',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt Rescue Challenge',
                    style: AppTypography.bodyMedium(colors.onShell),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.mono(colors.onShellMuted, size: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onShellMuted,
              semanticLabel: 'Open event',
            ),
          ],
        ),
      ),
    );
  }
}
