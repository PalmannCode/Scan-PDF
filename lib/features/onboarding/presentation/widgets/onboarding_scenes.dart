import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/paper_sheet_illustration.dart';
import 'package:scanpdf/core/widgets/signature/scan_pulse_frame.dart';

/// Scene 1 — the signature scan frame sweeping a paper sheet.
class ScanSceneIllustration extends StatelessWidget {
  const ScanSceneIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 220,
      height: 260,
      child: ScanPulseFrame(
        inset: 24,
        child: Center(child: PaperSheetIllustration(size: 170)),
      ),
    );
  }
}

/// Scene 2 — a page with crop handles and a signature stroke drawing in.
class EditSceneIllustration extends StatelessWidget {
  const EditSceneIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 220,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const PaperSheetIllustration(size: 190),
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _CropHandlesPainter(color: colors.accent),
              ),
            ),
          ),
          Positioned(
                bottom: 56,
                child: ExcludeSemantics(
                  child: CustomPaint(
                    size: const Size(110, 40),
                    painter: _SignatureStrokePainter(
                      color: colors.onShell.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              )
              .animate(
                onPlay: (c) => c.repeat(reverse: true, period: 4.seconds),
              )
              .fadeIn(duration: 900.ms, curve: AppMotion.enter),
        ],
      ),
    );
  }
}

/// Scene 3 — a sheet fanning into export format chips.
class ExportSceneIllustration extends StatelessWidget {
  const ExportSceneIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const formats = ['PDF', 'JPG', 'PNG', 'TXT'];
    return SizedBox(
      width: 240,
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PaperSheetIllustration(size: 150),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < formats.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child:
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          // accentDeep for the white-labelled chip: white on
                          // #FF7A2E is 2.6:1, on #F2600F it clears 3:1.
                          color: i == 0
                              ? colors.accentDeep
                              : colors.onShell.withValues(alpha: 0.14),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AppShapes.chip),
                          ),
                        ),
                        child: Text(
                          formats[i],
                          style: AppTypography.mono(
                            i == 0 ? Colors.white : colors.onShellMuted,
                            size: 12,
                          ),
                        ),
                      ).animate().fadeIn(
                        delay: (120 * i).ms,
                        duration: AppMotion.standard,
                        curve: AppMotion.enter,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CropHandlesPainter extends CustomPainter {
  const _CropHandlesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const arm = 14.0;
    final inset = Offset(size.width * 0.14, size.height * 0.1);
    final corners = [
      inset,
      Offset(size.width - inset.dx, inset.dy),
      Offset(inset.dx, size.height - inset.dy),
      Offset(size.width - inset.dx, size.height - inset.dy),
    ];
    for (final c in corners) {
      final dx = c.dx < size.width / 2 ? 1 : -1;
      final dy = c.dy < size.height / 2 ? 1 : -1;
      canvas.drawLine(c, Offset(c.dx + dx * arm, c.dy), paint);
      canvas.drawLine(c, Offset(c.dx, c.dy + dy * arm), paint);
    }
  }

  @override
  bool shouldRepaint(_CropHandlesPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SignatureStrokePainter extends CustomPainter {
  const _SignatureStrokePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..cubicTo(
        size.width * 0.2,
        -size.height * 0.4,
        size.width * 0.32,
        size.height * 1.3,
        size.width * 0.52,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.66,
        -size.height * 0.1,
        size.width * 0.78,
        size.height * 0.9,
        size.width,
        size.height * 0.35,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SignatureStrokePainter oldDelegate) =>
      oldDelegate.color != color;
}
