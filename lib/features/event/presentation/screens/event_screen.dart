import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/constants/app_constants.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/app_background.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/core/widgets/signature/scan_pulse_frame.dart';
import 'package:scanpdf/features/event/domain/event_phase.dart';
import 'package:scanpdf/features/event/presentation/providers/event_provider.dart';
import 'package:scanpdf/features/event/presentation/widgets/fading_receipt.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_session_provider.dart';

/// Receipt Rescue Challenge (In-App Event, Guideline 2.3.13):
/// time-boxed, fully local, free, and always openable — before the start
/// date it shows the start date and scanning still works; progress only
/// accrues during the live window.
class EventScreen extends ConsumerStatefulWidget {
  const EventScreen({super.key});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Countdown + phase flips re-render once a second while open.
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _countdownTo(DateTime target) {
    final left = target.difference(DateTime.now());
    if (left.isNegative) return '0d 00:00:00';
    final days = left.inDays;
    final hours = left.inHours % 24;
    final minutes = left.inMinutes % 60;
    final seconds = left.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${days}d ${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  void _rescue() {
    ref.read(scanSessionProvider.notifier).start(fromEvent: true);
    context.push('/camera');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final phase = currentEventPhase();
    final progress = ref.watch(receiptRescueProvider);
    final done = progress.rescuedCount >= AppConstants.eventGoal;

    return Scaffold(
      backgroundColor: colors.shellBg,
      body: AppBackground(
        treatment: BackgroundTreatment.shell,
        child: SafeArea(
          child: Column(
            children: [
              _EventHeader(onBack: () => context.canPop()
                  ? context.pop()
                  : context.go('/')),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      const SizedBox(
                        width: 210,
                        height: 260,
                        child: ScanPulseFrame(
                          inset: 22,
                          child:
                              Center(child: FadingReceipt(width: 140)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Receipt Rescue Challenge',
                        textAlign: TextAlign.center,
                        style: AppTypography.display(colors.onShell),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Thermal receipts fade to blank within months. '
                        'Rescue ${AppConstants.eventGoal} of them — warranties, '
                        'refunds, expenses — into permanent PDFs before the '
                        'ink disappears.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(colors.onShellMuted),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _PhasePanel(
                        phase: phase,
                        countdown: phase == EventPhase.upcoming
                            ? _countdownTo(AppConstants.eventStart)
                            : _countdownTo(AppConstants.eventEnd),
                        rescued: progress.rescuedCount,
                        done: done,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (phase != EventPhase.ended)
                        PressableTap(
                          onTap: _rescue,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                colors.accent,
                                colors.accentDeep,
                              ]),
                              borderRadius: AppShapes.buttonRadius,
                            ),
                            child: Text(
                              'Rescue a receipt',
                              textAlign: TextAlign.center,
                              style: AppTypography.title(Colors.white),
                            ),
                          ),
                        ),
                      if (phase == EventPhase.upcoming) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'You can scan receipts now — challenge progress '
                          'starts counting on '
                          '${DateFormat.MMMd().format(AppConstants.eventStart)}.',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption(
                              colors.onShellMuted),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventHeader extends StatelessWidget {
  const _EventHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          PressableTap(
            style: PressStyle.dim,
            onTap: onBack,
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: colors.onShell,
                size: 20,
                semanticLabel: 'Back'),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.16),
              borderRadius: AppShapes.pillRadius,
            ),
            child: Text(
              'CHALLENGE',
              style: AppTypography.label(colors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhasePanel extends StatelessWidget {
  const _PhasePanel({
    required this.phase,
    required this.countdown,
    required this.rescued,
    required this.done,
  });

  final EventPhase phase;
  final String countdown;
  final int rescued;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = switch (phase) {
      EventPhase.upcoming =>
        'Starts ${DateFormat.yMMMd().format(AppConstants.eventStart)}',
      EventPhase.live => done ? 'Challenge complete!' : 'Live now',
      EventPhase.ended => 'Challenge ended',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.shellElevated,
        borderRadius: AppShapes.cardRadius,
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTypography.title(
                  done ? colors.success : colors.onShell)),
          const SizedBox(height: AppSpacing.sm),
          if (phase != EventPhase.ended)
            Text(
              phase == EventPhase.upcoming
                  ? 'T-minus $countdown'
                  : '$countdown left',
              style: AppTypography.mono(colors.onShellMuted, size: 13),
            ),
          if (phase != EventPhase.upcoming) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$rescued',
                    style: AppTypography.monoLarge(colors.accent)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    ' / ${AppConstants.eventGoal} rescued',
                    style: AppTypography.mono(colors.onShellMuted,
                        size: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppShapes.pillRadius,
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(
                        color:
                            colors.onShell.withValues(alpha: 0.12)),
                    AnimatedFractionallySizedBox(
                      duration: AppMotion.sheet,
                      curve: AppMotion.enter,
                      widthFactor: (rescued / AppConstants.eventGoal)
                          .clamp(0.0, 1.0),
                      child: Container(color: colors.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
