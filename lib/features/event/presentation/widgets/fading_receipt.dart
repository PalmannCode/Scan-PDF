import 'package:flutter/material.dart';

import 'package:scanpdf/app/theme/app_colors.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';

/// Custom-painted thermal receipt whose ink fades toward the bottom —
/// the Receipt Rescue Challenge motif. [pulse] (0..1) breathes the fade.
class FadingReceipt extends StatefulWidget {
  const FadingReceipt({
    super.key,
    this.width = 150,
    this.height = 200,
    this.animated = true,
  });

  final double width;
  final double height;
  final bool animated;

  @override
  State<FadingReceipt> createState() => _FadingReceiptState();
}

class _FadingReceiptState extends State<FadingReceipt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Paper and ink are fixed light-theme values, not the flipping
    // `paperCard`/`textPrimary` tokens: this illustration only ever renders
    // on the dark indigo shell, which is identical in both themes. In dark
    // mode `paperCard` resolves to #211D48 against a #26214F shell (1.2:1),
    // so the receipt silhouette vanishes and the ink flips light-on-light.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _FadingReceiptPainter(
            paper: AppColors.paperWhite,
            ink: AppColors.navyText,
            accent: colors.accent,
            pulse: widget.animated
                ? Curves.easeInOutSine.transform(_controller.value)
                : 0.5,
            totalStyle: AppTypography.mono(AppColors.navyText, size: 9),
          ),
        ),
      ),
    );
  }
}

class _FadingReceiptPainter extends CustomPainter {
  const _FadingReceiptPainter({
    required this.paper,
    required this.ink,
    required this.accent,
    required this.pulse,
    required this.totalStyle,
  });

  final Color paper;
  final Color ink;
  final Color accent;
  final double pulse;
  final TextStyle totalStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const teeth = 8;

    // Receipt body with zigzag bottom edge.
    final body = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - 8);
    for (var i = teeth; i >= 0; i--) {
      final x = w * i / teeth;
      body.lineTo(x, i.isEven ? h - 8 : h);
    }
    body
      ..lineTo(0, h - 8)
      ..close();
    canvas.drawShadow(body, Colors.black.withValues(alpha: 0.4), 6, false);
    canvas.drawPath(body, Paint()..color = paper);

    // Ink lines fading toward the bottom; the pulse breathes the fade.
    const lines = 8;
    final left = w * 0.12;
    for (var i = 0; i < lines; i++) {
      final y = h * 0.14 + i * h * 0.085;
      final fade = 1 - (i / lines) * (0.55 + 0.35 * pulse);
      final right = i.isEven ? w * 0.88 : w * 0.62;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        Paint()
          ..color = ink.withValues(alpha: fade.clamp(0.06, 1.0) * 0.75)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // Dashed divider + TOTAL row in accent, still readable — the part
    // worth rescuing.
    final dividerY = h * 0.84;
    const dash = 6.0;
    var x = left;
    while (x < w * 0.88) {
      canvas.drawLine(
        Offset(x, dividerY),
        Offset((x + dash).clamp(0, w * 0.88), dividerY),
        Paint()
          ..color = ink.withValues(alpha: 0.35)
          ..strokeWidth = 1.5,
      );
      x += dash * 2;
    }
    final textPainter = TextPainter(
      text: TextSpan(text: 'TOTAL', style: totalStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(left, dividerY + 6));
    canvas.drawLine(
      Offset(w * 0.55, dividerY + 11),
      Offset(w * 0.88, dividerY + 11),
      Paint()
        ..color = accent
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FadingReceiptPainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.paper != paper;
}
