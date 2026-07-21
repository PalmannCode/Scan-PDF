import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_session_provider.dart';

/// Manual corner-adjustment crop (Jira §14). Corners persist on the
/// session page as a normalized quad; the perspective rectify happens at
/// save time in ScannerService.
class CropScreen extends ConsumerStatefulWidget {
  const CropScreen({super.key, required this.pageIndex});

  final int pageIndex;

  @override
  ConsumerState<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends ConsumerState<CropScreen> {
  ui.Image? _image;

  /// Normalized corners TL, TR, BR, BL.
  late List<Offset> _corners;
  int? _dragging;

  static const _defaultInset = 0.04;

  @override
  void initState() {
    super.initState();
    final page =
        ref.read(scanSessionProvider).pages[widget.pageIndex];
    final c = page.corners;
    _corners = c != null && c.length == 8
        ? [
            Offset(c[0], c[1]),
            Offset(c[2], c[3]),
            Offset(c[4], c[5]),
            Offset(c[6], c[7]),
          ]
        : _fullFrame();
    _loadImage(page.tempPath);
  }

  List<Offset> _fullFrame() => const [
        Offset(_defaultInset, _defaultInset),
        Offset(1 - _defaultInset, _defaultInset),
        Offset(1 - _defaultInset, 1 - _defaultInset),
        Offset(_defaultInset, 1 - _defaultInset),
      ];

  Future<void> _loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final image = await decodeImageFromList(bytes);
    if (mounted) setState(() => _image = image);
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Rect _displayRect(Size box) {
    final image = _image!;
    final scale = math.min(
      box.width / image.width,
      box.height / image.height,
    );
    final size =
        Size(image.width * scale, image.height * scale);
    final offset = Offset(
      (box.width - size.width) / 2,
      (box.height - size.height) / 2,
    );
    return offset & size;
  }

  void _onPanStart(Offset local, Rect rect) {
    var best = -1;
    var bestDist = 40.0;
    for (var i = 0; i < 4; i++) {
      final p = Offset(
        rect.left + _corners[i].dx * rect.width,
        rect.top + _corners[i].dy * rect.height,
      );
      final d = (p - local).distance;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    if (best >= 0) {
      Haptics.selection();
      setState(() => _dragging = best);
    }
  }

  void _onPanUpdate(Offset local, Rect rect) {
    final index = _dragging;
    if (index == null) return;
    setState(() {
      _corners[index] = Offset(
        ((local.dx - rect.left) / rect.width).clamp(0, 1),
        ((local.dy - rect.top) / rect.height).clamp(0, 1),
      );
    });
  }

  void _apply() {
    final notifier = ref.read(scanSessionProvider.notifier);
    final page =
        ref.read(scanSessionProvider).pages[widget.pageIndex];
    notifier.updatePage(
      widget.pageIndex,
      page.copyWith(corners: [
        for (final corner in _corners) ...[corner.dx, corner.dy],
      ]),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.shellBgDeep,
      appBar: AppBar(
        leading: PressableTap(
          style: PressStyle.dim,
          onTap: () => context.pop(),
          child: Icon(Icons.close_rounded,
              color: colors.onShell, semanticLabel: 'Cancel crop'),
        ),
        title: Text('Crop',
            style: AppTypography.title(colors.onShell)),
        actions: [
          PressableTap(
            style: PressStyle.dim,
            onTap: () => setState(() => _corners = _fullFrame()),
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Text('Reset',
                  style: AppTypography.bodyMedium(colors.onShellMuted)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _image == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final rect =
                              _displayRect(constraints.biggest);
                          return GestureDetector(
                            onPanStart: (d) =>
                                _onPanStart(d.localPosition, rect),
                            onPanUpdate: (d) =>
                                _onPanUpdate(d.localPosition, rect),
                            onPanEnd: (_) =>
                                setState(() => _dragging = null),
                            child: CustomPaint(
                              size: constraints.biggest,
                              painter: _CropPainter(
                                image: _image!,
                                rect: rect,
                                corners: _corners,
                                accent: colors.accent,
                                dragging: _dragging,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: PressableTap(
                onTap: _apply,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: AppShapes.buttonRadius,
                  ),
                  child: Text(
                    'Apply crop',
                    textAlign: TextAlign.center,
                    style: AppTypography.title(Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter({
    required this.image,
    required this.rect,
    required this.corners,
    required this.accent,
    required this.dragging,
  });

  final ui.Image image;
  final Rect rect;
  final List<Offset> corners;
  final Color accent;
  final int? dragging;

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    Offset point(int i) => Offset(
          rect.left + corners[i].dx * rect.width,
          rect.top + corners[i].dy * rect.height,
        );
    final quad = Path()
      ..moveTo(point(0).dx, point(0).dy)
      ..lineTo(point(1).dx, point(1).dy)
      ..lineTo(point(2).dx, point(2).dy)
      ..lineTo(point(3).dx, point(3).dy)
      ..close();

    // Dim everything outside the quad.
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      quad,
    );
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    canvas.drawPath(
      quad,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (var i = 0; i < 4; i++) {
      final active = dragging == i;
      canvas.drawCircle(
        point(i),
        active ? 14 : 10,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        point(i),
        active ? 9 : 6,
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) =>
      oldDelegate.corners != corners ||
      oldDelegate.dragging != dragging ||
      oldDelegate.rect != rect;
}
