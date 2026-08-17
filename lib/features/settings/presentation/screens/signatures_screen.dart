import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/viewer/data/signature_renderer.dart';
import 'package:scanpdf/features/viewer/presentation/providers/viewer_actions_provider.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

class SignaturesScreen extends ConsumerStatefulWidget {
  const SignaturesScreen({super.key});

  @override
  ConsumerState<SignaturesScreen> createState() => _SignaturesScreenState();
}

class _SignaturesScreenState extends ConsumerState<SignaturesScreen> {
  final List<List<Offset>> _strokes = [];
  bool _saving = false;

  Future<void> _save() async {
    final png = await SignatureRenderer.render(_strokes);
    if (png == null || !mounted) return;
    final name = await AdaptiveDialog.prompt(
      context,
      title: 'Name this signature',
      placeholder: 'e.g. Full signature',
      confirmLabel: 'Save',
    );
    if (name == null) return;
    setState(() => _saving = true);
    final store = ref.read(signatureStoreProvider);
    final saved = await store.save(png, name);
    if (store.defaultId == null) await store.setDefault(saved.id);
    await ref
        .read(analyticsServiceProvider)
        .track('signature_saved', properties: {'screen_name': 'signatures'});
    if (mounted) {
      setState(() {
        _saving = false;
        _strokes.clear();
      });
    }
  }

  Future<void> _rename(String id, String current) async {
    final name = await AdaptiveDialog.prompt(
      context,
      title: 'Rename signature',
      initialValue: current,
      confirmLabel: 'Rename',
    );
    if (name == null) return;
    await ref.read(signatureStoreProvider).rename(id, name);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plus = ref.watch(plusProvider.select((state) => state.isActive));
    final store = ref.watch(signatureStoreProvider);
    final saved = store.getAll();
    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          onTap: () => context.pop(),
          child: Icon(Icons.close_rounded, color: colors.textPrimary),
        ),
        title: Text(
          'Signatures',
          style: AppTypography.title(colors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: !plus
            ? _LockedSignatures(onUpgrade: () => context.push('/paywall'))
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Create signature',
                    style: AppTypography.headline(colors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Draw inside the box. Saved signatures stay local unless cloud sync is enabled.',
                    style: AppTypography.body(colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    height: 220,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: colors.paperCard,
                      borderRadius: AppShapes.cardRadius,
                      border: Border.all(color: colors.hairline),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) =>
                          setState(() => _strokes.add([details.localPosition])),
                      onPanUpdate: (details) => setState(
                        () => _strokes.last.add(details.localPosition),
                      ),
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          ink: colors.textPrimary,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _strokes.isEmpty
                              ? null
                              : () => setState(_strokes.clear),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: _strokes.isEmpty || _saving ? null : _save,
                          child: Text(_saving ? 'Saving…' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Saved signatures',
                    style: AppTypography.headline(colors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (saved.isEmpty)
                    Text(
                      'No saved signatures yet.',
                      style: AppTypography.body(colors.textSecondary),
                    ),
                  for (final signature in saved)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.paperCard,
                        borderRadius: AppShapes.cardRadius,
                        border: Border.all(color: colors.hairline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 88,
                            height: 50,
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            color: Colors.white,
                            child: Image.file(
                              File(
                                ref.read(resolvePathProvider)(
                                  signature.fileName,
                                ),
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  signature.name,
                                  style: AppTypography.bodyMedium(
                                    colors.textPrimary,
                                  ),
                                ),
                                if (store.isDefault(signature.id))
                                  Text(
                                    'Default',
                                    style: AppTypography.caption(colors.accent),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'default') {
                                await store.setDefault(signature.id);
                              } else if (action == 'rename') {
                                await _rename(signature.id, signature.name);
                              } else if (action == 'delete') {
                                await store.delete(signature.id);
                              }
                              if (mounted) setState(() {});
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'default',
                                child: Text('Set as default'),
                              ),
                              const PopupMenuItem(
                                value: 'rename',
                                child: Text('Rename'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
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

class _LockedSignatures extends StatelessWidget {
  const _LockedSignatures({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.draw_outlined, size: 64, color: colors.accent),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Reusable signatures are a Plus feature',
            textAlign: TextAlign.center,
            style: AppTypography.headline(colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Drawing and applying a one-time signature remains available for everyone.',
            textAlign: TextAlign.center,
            style: AppTypography.body(colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: onUpgrade, child: const Text('View Plus')),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes, required this.ink});

  final List<List<Offset>> strokes;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.5, Paint()..color = ink);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
