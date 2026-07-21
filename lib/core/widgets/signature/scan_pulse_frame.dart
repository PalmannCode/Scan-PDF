import 'package:flutter/material.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';

/// THE signature component (Design Brief axis 7).
///
/// Four orange corner brackets — the universal scan-viewfinder glyph —
/// drawn with rounded caps around [child], with a soft-edged scan beam
/// sweeping top to bottom on a slow loop and precision tick marks on the
/// left rail. Custom-painted; used on the home empty state, as the camera
/// capture overlay, and framing the Receipt Rescue event illustration.
class ScanPulseFrame extends StatefulWidget {
  const ScanPulseFrame({
    super.key,
    this.child,
    this.animated = true,
    this.showTicks = true,
    this.strokeWidth = 3,
    this.inset = 10,
  });

  final Widget? child;
  final bool animated;
  final bool showTicks;
  final double strokeWidth;

  /// Gap between the brackets and the child content.
  final double inset;

  @override
  State<ScanPulseFrame> createState() => _ScanPulseFrameState();
}

class _ScanPulseFrameState extends State<ScanPulseFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.beamSweep,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) _controller.repeat();
  }

  @override
  void didUpdateWidget(ScanPulseFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          foregroundPainter: _ScanPulsePainter(
            progress: widget.animated
                ? AppMotion.ambient.transform(_controller.value)
                : -1,
            bracketColor: colors.accent,
            beamColor: colors.accent,
            tickColor: colors.onShellMuted.withValues(alpha: 0.5),
            strokeWidth: widget.strokeWidth,
            showTicks: widget.showTicks,
          ),
          child: child,
        ),
        child: Padding(
          padding: EdgeInsets.all(widget.inset + widget.strokeWidth),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ScanPulsePainter extends CustomPainter {
  const _ScanPulsePainter({
    required this.progress,
    required this.bracketColor,
    required this.beamColor,
    required this.tickColor,
    required this.strokeWidth,
    required this.showTicks,
  });

  /// 0..1 beam position; -1 hides the beam (static variant).
  final double progress;
  final Color bracketColor;
  final Color beamColor;
  final Color tickColor;
  final double strokeWidth;
  final bool showTicks;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final arm = (w < h ? w : h) * 0.18;
    const r = 6.0;

    final bracket = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Path corner(Offset origin, double dx, double dy) => Path()
      ..moveTo(origin.dx + dx * arm, origin.dy)
      ..lineTo(origin.dx + dx * r, origin.dy)
      ..quadraticBezierTo(
          origin.dx, origin.dy, origin.dx, origin.dy + dy * r)
      ..lineTo(origin.dx, origin.dy + dy * arm);

    canvas.drawPath(corner(Offset.zero, 1, 1), bracket);
    canvas.drawPath(corner(Offset(w, 0), -1, 1), bracket);
    canvas.drawPath(corner(Offset(0, h), 1, -1), bracket);
    canvas.drawPath(corner(Offset(w, h), -1, -1), bracket);

    if (showTicks) {
      final tick = Paint()
        ..color = tickColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final railTop = h * 0.28;
      final railBottom = h * 0.72;
      const count = 5;
      for (var i = 0; i < count; i++) {
        final y = railTop + (railBottom - railTop) * i / (count - 1);
        final long = i.isEven;
        canvas.drawLine(
          Offset(-strokeWidth - 4, y),
          Offset(-strokeWidth - 4 - (long ? 8 : 5), y),
          tick,
        );
      }
    }

    if (progress >= 0) {
      final beamY = h * 0.06 + (h * 0.88) * progress;
      final trail = Rect.fromLTWH(0, beamY - 26, w, 26);
      canvas.drawRect(
        trail,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              beamColor.withValues(alpha: 0),
              beamColor.withValues(alpha: 0.14),
            ],
          ).createShader(trail),
      );
      canvas.drawLine(
        Offset(w * 0.03, beamY),
        Offset(w * 0.97, beamY),
        Paint()
          ..color = beamColor.withValues(alpha: 0.9)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanPulsePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.bracketColor != bracketColor;
}
