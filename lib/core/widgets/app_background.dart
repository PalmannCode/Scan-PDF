import 'package:flutter/material.dart';

import 'package:scanpdf/core/extensions/context_extensions.dart';

/// Background treatments from the Design Brief: the dark indigo shell
/// (flat with a subtle vertical deepening + oversized bracket motif) and
/// flat paper for light screens. Static — no mesh, no animation.
enum BackgroundTreatment { shell, paper }

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.treatment,
    required this.child,
  });

  final BackgroundTreatment treatment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (treatment == BackgroundTreatment.paper) {
      return ColoredBox(color: colors.paperBg, child: child);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.shellBg, colors.shellBgDeep],
                stops: const [0.55, 1],
              ),
            ),
            child: CustomPaint(
              painter: _BracketMotifPainter(
                color: colors.onShell.withValues(alpha: 0.035),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Oversized fragments of the ScanPulseFrame corner brackets, barely
/// visible — the signature motif echoed into the shell background.
class _BracketMotifPainter extends CustomPainter {
  const _BracketMotifPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Top-right oversized bracket, partially off-canvas.
    final arm = size.width * 0.42;
    canvas.drawPath(
      Path()
        ..moveTo(size.width - arm, -size.height * 0.06)
        ..lineTo(size.width * 1.06, -size.height * 0.06)
        ..lineTo(size.width * 1.06, size.height * 0.2),
      paint,
    );
    // Bottom-left fragment.
    canvas.drawPath(
      Path()
        ..moveTo(-size.width * 0.08, size.height * 0.62)
        ..lineTo(-size.width * 0.08, size.height * 0.86)
        ..lineTo(size.width * 0.26, size.height * 0.86),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BracketMotifPainter oldDelegate) =>
      oldDelegate.color != color;
}
