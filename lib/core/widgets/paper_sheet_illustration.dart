import 'package:flutter/material.dart';

import 'package:scanpdf/core/extensions/context_extensions.dart';

/// Custom-painted document sheet used by empty states, onboarding scenes
/// and error views — a rounded sheet with a folded top-right corner and
/// printed text lines, drawn in the app's shape language.
class PaperSheetIllustration extends StatelessWidget {
  const PaperSheetIllustration({
    super.key,
    this.size = 120,
    this.onShell = true,
    this.torn = false,
  });

  final double size;

  /// True when drawn on the dark indigo shell (muted sheet), false on paper.
  final bool onShell;

  /// Torn bottom edge variant for error views.
  final bool torn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size * 0.78, size),
        painter: _PaperSheetPainter(
          sheet: onShell
              ? colors.onShell.withValues(alpha: 0.16)
              : colors.paperCard,
          fold: onShell
              ? colors.onShell.withValues(alpha: 0.3)
              : colors.hairline,
          line: onShell
              ? colors.onShell.withValues(alpha: 0.32)
              : colors.textSecondary.withValues(alpha: 0.4),
          outline: onShell ? Colors.transparent : colors.hairline,
          torn: torn,
        ),
      ),
    );
  }
}

class _PaperSheetPainter extends CustomPainter {
  const _PaperSheetPainter({
    required this.sheet,
    required this.fold,
    required this.line,
    required this.outline,
    required this.torn,
  });

  final Color sheet;
  final Color fold;
  final Color line;
  final Color outline;
  final bool torn;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final foldSize = w * 0.24;
    const r = 8.0;

    final body = Path()
      ..moveTo(r, 0)
      ..lineTo(w - foldSize, 0)
      ..lineTo(w, foldSize)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h);
    if (torn) {
      const teeth = 7;
      for (var i = teeth; i >= 0; i--) {
        final x = r + (w - 2 * r) * i / teeth;
        body.lineTo(x, i.isEven ? h : h - 7);
      }
    } else {
      body.lineTo(r, h);
    }
    body
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();

    canvas.drawPath(body, Paint()..color = sheet);
    if (outline.a > 0) {
      canvas.drawPath(
        body,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Folded corner triangle.
    canvas.drawPath(
      Path()
        ..moveTo(w - foldSize, 0)
        ..lineTo(w - foldSize, foldSize)
        ..lineTo(w, foldSize)
        ..close(),
      Paint()..color = fold,
    );

    // Printed lines.
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final left = w * 0.16;
    for (var i = 0; i < 4; i++) {
      final y = h * 0.3 + i * h * 0.14;
      final right = i == 3 ? w * 0.52 : w * 0.84;
      canvas.drawLine(Offset(left, y), Offset(right, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_PaperSheetPainter oldDelegate) =>
      oldDelegate.sheet != sheet || oldDelegate.torn != torn;
}
