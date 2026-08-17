import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/viewer/data/signature_renderer.dart';
import 'package:scanpdf/features/viewer/presentation/providers/viewer_actions_provider.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

/// Sign flow (Jira §12 Edit → Sign): draw or pick a signature, drag and
/// pinch it into place on a page, then bake it into the page image.
class SignScreen extends ConsumerStatefulWidget {
  const SignScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends ConsumerState<SignScreen> {
  final List<List<Offset>> _strokes = [];
  Uint8List? _signaturePng;
  int _pageIndex = 0;

  // Placement state (normalized to the page image box).
  Offset _center = const Offset(0.5, 0.72);
  double _widthFraction = 0.34;
  Offset? _dragStartCenter;
  double _scaleStartWidth = 0.34;
  bool _applying = false;
  bool _applyToAllPages = false;

  Future<Uint8List?> _renderSignature() async {
    return SignatureRenderer.render(_strokes);
  }

  Future<void> _useDrawn() async {
    final png = await _renderSignature();
    if (png == null) return;
    setState(() => _signaturePng = png);
  }

  Future<void> _saveDrawnForReuse() async {
    final plus = ref.read(plusProvider);
    if (!plus.isActive) {
      context.push('/paywall');
      return;
    }
    final png = await _renderSignature();
    if (png == null || !mounted) return;
    final name = await AdaptiveDialog.prompt(
      context,
      title: 'Name this signature',
      placeholder: 'e.g. Initials',
      confirmLabel: 'Save',
    );
    if (name == null) return;
    await ref.read(signatureStoreProvider).save(png, name);
    if (mounted) setState(() {});
  }

  Future<void> _pickSignatureImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _signaturePng = bytes);
  }

  Future<void> _apply() async {
    final png = _signaturePng;
    final doc = ref.read(documentByIdProvider(widget.documentId));
    if (png == null || doc == null || _applying) return;
    setState(() => _applying = true);
    try {
      await ref
          .read(viewerActionsProvider)
          .applySignature(
            document: doc,
            pageIndices: _applyToAllPages
                ? List<int>.generate(doc.pageCount, (index) => index)
                : [_pageIndex],
            signaturePng: png,
            centerX: _center.dx,
            centerY: _center.dy,
            widthFraction: _widthFraction,
          );
      Haptics.success();
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final doc = ref.watch(documentByIdProvider(widget.documentId));
    if (doc == null || doc.pages.isEmpty) {
      return Scaffold(backgroundColor: colors.paperBg);
    }
    _pageIndex = _pageIndex.clamp(0, doc.pageCount - 1);

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          style: PressStyle.dim,
          onTap: () => context.pop(),
          child: Icon(
            Icons.close_rounded,
            color: colors.textPrimary,
            semanticLabel: 'Cancel',
          ),
        ),
        title: Text('Sign', style: AppTypography.title(colors.textPrimary)),
        actions: [
          if (_signaturePng != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: PressableTap(
                onTap: _applying ? null : _apply,
                enabled: !_applying,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(
                      alpha: _applying ? 0.55 : 1,
                    ),
                    borderRadius: AppShapes.pillRadius,
                  ),
                  child: Text(
                    _applying ? 'Applying…' : 'Apply',
                    style: AppTypography.bodyMedium(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _signaturePng == null
            ? _buildDrawStage()
            : _buildPlaceStage(doc),
      ),
    );
  }

  Widget _buildDrawStage() {
    final colors = context.colors;
    final saved = ref.watch(signatureStoreProvider).getAll();
    final plusActive = ref.watch(plusProvider.select((s) => s.isActive));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.paperCard,
                borderRadius: AppShapes.cardRadius,
                border: Border.all(color: colors.hairline),
              ),
              clipBehavior: Clip.antiAlias,
              child: RepaintBoundary(
                child: GestureDetector(
                  onPanStart: (d) =>
                      setState(() => _strokes.add([d.localPosition])),
                  onPanUpdate: (d) =>
                      setState(() => _strokes.last.add(d.localPosition)),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _StrokesPainter(
                      strokes: _strokes,
                      color: colors.textPrimary,
                      background: colors.paperCard,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PressableTap(
                  onTap: _strokes.isEmpty
                      ? null
                      : () => setState(_strokes.clear),
                  enabled: _strokes.isNotEmpty,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: colors.toolCard,
                      borderRadius: AppShapes.buttonRadius,
                    ),
                    child: Text(
                      'Clear',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(colors.textPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PressableTap(
                  onTap: _strokes.isEmpty ? null : _useDrawn,
                  enabled: _strokes.isNotEmpty,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: _strokes.isEmpty
                          ? colors.accent.withValues(alpha: 0.4)
                          : colors.accent,
                      borderRadius: AppShapes.buttonRadius,
                    ),
                    child: Text(
                      'Use signature',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _pickSignatureImage,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Use signature image'),
          ),
          const SizedBox(height: AppSpacing.md),
          PressableTap(
            onTap: _strokes.isEmpty ? null : _saveDrawnForReuse,
            enabled: _strokes.isNotEmpty,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  plusActive
                      ? Icons.bookmark_add_outlined
                      : Icons.lock_outline_rounded,
                  size: 16,
                  color: colors.accent,
                  semanticLabel: 'Save signature',
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  plusActive ? 'Save for reuse' : 'Save for reuse — Plus',
                  style: AppTypography.caption(colors.accent),
                ),
              ],
            ),
          ),
          if (saved.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Saved signatures',
              style: AppTypography.label(colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: saved.length,
                itemBuilder: (context, index) {
                  final signature = saved[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: PressableTap(
                      onTap: () async {
                        if (!plusActive) {
                          context.push('/paywall');
                          return;
                        }
                        final png = await ref
                            .read(signatureStoreProvider)
                            .read(signature);
                        setState(() => _signaturePng = png);
                      },
                      onLongPress: () async {
                        await ref
                            .read(signatureStoreProvider)
                            .delete(signature.id);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: colors.toolCard,
                          borderRadius: AppShapes.thumbnailRadius,
                        ),
                        child: Column(
                          children: [
                            Image.file(
                              File(
                                ref.read(resolvePathProvider)(
                                  signature.fileName,
                                ),
                              ),
                              height: 24,
                              errorBuilder: (context, _, _) =>
                                  const SizedBox(width: 24, height: 24),
                            ),
                            Text(
                              signature.name,
                              style: AppTypography.caption(
                                colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceStage(ScanDocument doc) {
    final colors = context.colors;
    final resolve = ref.read(resolvePathProvider);
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Stack(
                children: [
                  Image.file(
                    File(resolve(doc.pages[_pageIndex].processedFileName)),
                    fit: BoxFit.contain,
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final box = constraints.biggest;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: (_) {
                            _dragStartCenter = _center;
                            _scaleStartWidth = _widthFraction;
                          },
                          onScaleUpdate: (details) => setState(() {
                            final start = _dragStartCenter ?? _center;
                            _center = Offset(
                              (start.dx +
                                      details.focalPointDelta.dx / box.width)
                                  .clamp(0.05, 0.95),
                              (start.dy +
                                      details.focalPointDelta.dy / box.height)
                                  .clamp(0.05, 0.95),
                            );
                            _dragStartCenter = _center;
                            _widthFraction = (_scaleStartWidth * details.scale)
                                .clamp(0.1, 0.85);
                          }),
                          child: Align(
                            alignment: Alignment(
                              _center.dx * 2 - 1,
                              _center.dy * 2 - 1,
                            ),
                            child: SizedBox(
                              width: box.width * _widthFraction,
                              child: Image.memory(_signaturePng!),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                'Drag to position · pinch to resize',
                style: AppTypography.caption(colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (doc.pageCount > 1)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: doc.pageCount,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: PressableTap(
                        onTap: () => setState(() => _pageIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: index == _pageIndex
                                ? colors.accent
                                : colors.toolCard,
                            borderRadius: AppShapes.pillRadius,
                          ),
                          child: Text(
                            'Page ${index + 1}',
                            style: AppTypography.mono(
                              index == _pageIndex
                                  ? Colors.white
                                  : colors.textSecondary,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (doc.pageCount > 1)
                SwitchListTile.adaptive(
                  value: _applyToAllPages,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Apply to every page'),
                  onChanged: (value) =>
                      setState(() => _applyToAllPages = value),
                ),
              const SizedBox(height: AppSpacing.sm),
              PressableTap(
                onTap: () => setState(() => _signaturePng = null),
                child: Text(
                  'Back to drawing',
                  style: AppTypography.caption(colors.accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StrokesPainter extends CustomPainter {
  const _StrokesPainter({
    required this.strokes,
    required this.color,
    required this.background,
  });

  final List<List<Offset>> strokes;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 1.5, Paint()..color = color);
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter oldDelegate) => true;
}
