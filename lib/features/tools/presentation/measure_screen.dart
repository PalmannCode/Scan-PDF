import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';

class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen> {
  final _known = TextEditingController(text: '10');
  String _unit = 'cm';
  bool _editingReference = true;
  Offset _r1 = const Offset(0.2, 0.82);
  Offset _r2 = const Offset(0.8, 0.82);
  Offset _m1 = const Offset(0.3, 0.35);
  Offset _m2 = const Offset(0.7, 0.35);
  final GlobalKey _captureKey = GlobalKey();
  Size _viewSize = Size.zero;

  @override
  void dispose() {
    _known.dispose();
    super.dispose();
  }

  double get _result {
    final known = double.tryParse(_known.text) ?? 0;
    final reference = _lineLength(_r1, _r2);
    final measured = _lineLength(_m1, _m2);
    return reference <= 0 ? 0 : known * measured / reference;
  }

  double _lineLength(Offset a, Offset b) {
    if (_viewSize.isEmpty) return (a - b).distance;
    return Offset(
      (a.dx - b.dx) * _viewSize.width,
      (a.dy - b.dy) * _viewSize.height,
    ).distance;
  }

  void _move(Offset local, Size size) {
    final point = Offset(
      (local.dx / size.width).clamp(0, 1),
      (local.dy / size.height).clamp(0, 1),
    );
    setState(() {
      if (_editingReference) {
        if ((_r1 - point).distance < (_r2 - point).distance) {
          _r1 = point;
        } else {
          _r2 = point;
        }
      } else if ((_m1 - point).distance < (_m2 - point).distance) {
        _m1 = point;
      } else {
        _m2 = point;
      }
    });
  }

  Future<void> _shareResult() async {
    final boundary = _captureKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/measurement_result.png');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Measured: ${_result.toStringAsFixed(2)} $_unit',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: PressableTap(
          onTap: () => context.go('/'),
          child: const Icon(Icons.close_rounded, color: Colors.white),
        ),
        title: Text('Measure', style: AppTypography.title(Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  if (_viewSize != size) {
                    _viewSize = size;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() {});
                    });
                  }
                  return RepaintBoundary(
                    key: _captureKey,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (event) => _move(event.localPosition, size),
                      onPanUpdate: (event) => _move(event.localPosition, size),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                          ),
                          CustomPaint(
                            painter: _MeasurePainter(
                              r1: _r1,
                              r2: _r2,
                              m1: _m1,
                              m2: _m2,
                              activeReference: _editingReference,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              color: colors.paperCard,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _known,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Reference length',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      DropdownButton<String>(
                        value: _unit,
                        items: const [
                          DropdownMenuItem(value: 'cm', child: Text('cm')),
                          DropdownMenuItem(value: 'in', child: Text('inch')),
                        ],
                        onChanged: (value) =>
                            setState(() => _unit = value ?? 'cm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Set reference')),
                      ButtonSegment(
                        value: false,
                        label: Text('Measure object'),
                      ),
                    ],
                    selected: {_editingReference},
                    onSelectionChanged: (value) =>
                        setState(() => _editingReference = value.first),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Measured: ${_result.toStringAsFixed(2)} $_unit',
                    style: AppTypography.headline(colors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _shareResult,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Save or share result'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Place the orange line over an object of known length, then place the green line over the target.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurePainter extends CustomPainter {
  const _MeasurePainter({
    required this.r1,
    required this.r2,
    required this.m1,
    required this.m2,
    required this.activeReference,
  });

  final Offset r1;
  final Offset r2;
  final Offset m1;
  final Offset m2;
  final bool activeReference;

  @override
  void paint(Canvas canvas, Size size) {
    void line(Offset a, Offset b, Color color, bool active) {
      final p1 = Offset(a.dx * size.width, a.dy * size.height);
      final p2 = Offset(b.dx * size.width, b.dy * size.height);
      final paint = Paint()
        ..color = color
        ..strokeWidth = active ? 5 : 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, paint);
      canvas.drawCircle(p1, 10, paint);
      canvas.drawCircle(p2, 10, paint);
    }

    line(r1, r2, const Color(0xFFFF7A1A), activeReference);
    line(m1, m2, const Color(0xFF5AAE7D), !activeReference);
  }

  @override
  bool shouldRepaint(_MeasurePainter oldDelegate) => true;
}
