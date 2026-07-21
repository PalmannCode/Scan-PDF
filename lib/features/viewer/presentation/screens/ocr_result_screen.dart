import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/core/widgets/shimmer_loader.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_saver_provider.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

/// Recognized text for a document (Jira §20): view, copy, export.
class OcrResultScreen extends ConsumerStatefulWidget {
  const OcrResultScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<OcrResultScreen> createState() =>
      _OcrResultScreenState();
}

class _OcrResultScreenState extends ConsumerState<OcrResultScreen> {
  bool _running = false;

  Future<void> _runOcr() async {
    if (_running) return;
    setState(() => _running = true);
    await ref.read(scanSaverProvider).runOcr(widget.documentId);
    if (mounted) setState(() => _running = false);
  }

  @override
  void initState() {
    super.initState();
    final doc = ref.read(documentByIdProvider(widget.documentId));
    if (doc != null && !doc.hasOcr) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runOcr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final doc = ref.watch(documentByIdProvider(widget.documentId));
    if (doc == null) {
      return Scaffold(backgroundColor: colors.paperBg);
    }

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          style: PressStyle.dim,
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary,
              size: 20,
              semanticLabel: 'Back'),
        ),
        title: Text('Recognized text',
            style: AppTypography.title(colors.textPrimary)),
        actions: [
          if (doc.hasOcr) ...[
            PressableTap(
              style: PressStyle.dim,
              onTap: () async {
                await Clipboard.setData(
                    ClipboardData(text: doc.ocrText));
                Haptics.success();
              },
              child: Icon(Icons.copy_rounded,
                  color: colors.textPrimary,
                  size: 20,
                  semanticLabel: 'Copy all'),
            ),
            const SizedBox(width: AppSpacing.lg),
            PressableTap(
              style: PressStyle.dim,
              onTap: () =>
                  ref.read(exportServiceProvider).shareTxt(doc),
              child: Icon(Icons.ios_share_rounded,
                  color: colors.textPrimary,
                  size: 20,
                  semanticLabel: 'Share text'),
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
        ],
      ),
      body: SafeArea(
        child: _running
            ? const _OcrSkeleton()
            : !doc.hasOcr
                ? _NoTextView(onRun: _runOcr)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: doc.pages.length,
                    itemBuilder: (context, index) {
                      final page = doc.pages[index];
                      if (!page.hasOcr) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(
                            bottom: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colors.paperCard,
                          borderRadius: AppShapes.cardRadius,
                          border: Border.all(color: colors.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PAGE ${index + 1}',
                              style: AppTypography.mono(
                                  colors.textSecondary,
                                  size: 11),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SelectableText(
                              page.ocrText,
                              style: AppTypography.body(
                                  colors.textPrimary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _OcrSkeleton extends StatelessWidget {
  const _OcrSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 3,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 72, height: 12),
              SizedBox(height: AppSpacing.md),
              ShimmerBox(height: 14),
              SizedBox(height: AppSpacing.sm),
              ShimmerBox(height: 14),
              SizedBox(height: AppSpacing.sm),
              ShimmerBox(width: 220, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoTextView extends StatelessWidget {
  const _NoTextView({required this.onRun});

  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No text recognized yet',
              style: AppTypography.title(colors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Run text recognition on this document\'s pages.',
            style: AppTypography.body(colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          PressableTap(
            onTap: onRun,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: AppShapes.buttonRadius,
              ),
              child: Text('Recognize text',
                  style: AppTypography.bodyMedium(Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
