import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/app_bottom_sheet.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/home/presentation/widgets/document_actions.dart';
import 'package:scanpdf/features/home/presentation/widgets/document_tile.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_saver_provider.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/viewer/presentation/providers/viewer_actions_provider.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

class DocumentViewerScreen extends ConsumerStatefulWidget {
  const DocumentViewerScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  int _page = 0;
  bool _zoomed = false;

  Future<void> _rename(ScanDocument doc) async {
    final name = await AdaptiveDialog.prompt(
      context,
      title: 'Rename document',
      initialValue: doc.title,
    );
    if (name != null) {
      await ref.read(documentsProvider.notifier).rename(doc.id, name);
    }
  }

  Future<void> _trash(ScanDocument doc) async {
    final ok = await AdaptiveDialog.confirm(
      context,
      title: 'Move to trash?',
      message: 'You can restore it from the Trash Bin later.',
      confirmLabel: 'Move',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await ref.read(documentsProvider.notifier).moveToTrash(doc.id);
    if (mounted) context.pop();
  }

  Future<void> _export(ScanDocument doc) async {
    final export = ref.read(exportServiceProvider);
    // Captured up front: the text exports run OCR after the sheet is popped,
    // and without this a document that yields no text closed the sheet and
    // then did nothing at all.
    final messenger = ScaffoldMessenger.of(context);
    // Captured before the sheet pops: OCR can take ~20s, by which time this
    // sheet's context is gone and navigation through it would be swallowed.
    final router = GoRouter.of(context);
    await AppBottomSheet.show<void>(
      context,
      title: 'Export',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetAction(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF document',
              onTap: () async {
                Navigator.of(context).pop();
                await export.sharePdf(doc);
              },
            ),
            SheetAction(
              icon: Icons.image_outlined,
              label: 'JPG images',
              onTap: () async {
                Navigator.of(context).pop();
                await export.shareImages(doc, ExportFormat.jpg);
              },
            ),
            SheetAction(
              icon: Icons.image_outlined,
              label: 'PNG images',
              onTap: () async {
                Navigator.of(context).pop();
                await export.shareImages(doc, ExportFormat.png);
              },
            ),
            SheetAction(
              icon: Icons.notes_rounded,
              label: doc.hasOcr
                  ? 'Text (.txt)'
                  : 'Text (.txt) — runs OCR first',
              onTap: () async {
                Navigator.of(context).pop();
                if (!doc.hasOcr) {
                  await ref.read(scanSaverProvider).runOcr(doc.id);
                }
                final updated = ref
                    .read(documentRepositoryProvider)
                    .getById(doc.id);
                if (updated != null && updated.hasOcr) {
                  await export.shareTxt(updated);
                } else {
                  // Owner decision 2026-08-19: open the OCR screen so the user
                  // can see the per-page result and retry or type text in,
                  // rather than being told nothing happened.
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('No text recognized — opening text view.'),
                    ),
                  );
                  router.push('/document/${doc.id}/text');
                }
              },
            ),
            SheetAction(
              icon: Icons.description_outlined,
              label: 'Word document (.docx) — Plus',
              onTap: () async {
                Navigator.of(context).pop();
                if (!ref.read(plusProvider).isActive) {
                  context.push('/paywall');
                  return;
                }
                if (!doc.hasOcr) {
                  await ref.read(scanSaverProvider).runOcr(doc.id);
                }
                final updated = ref
                    .read(documentRepositoryProvider)
                    .getById(doc.id);
                if (updated != null && updated.hasOcr) {
                  await export.shareWord(updated);
                } else {
                  // Owner decision 2026-08-19: open the OCR screen so the user
                  // can see the per-page result and retry or type text in,
                  // rather than being told nothing happened.
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('No text recognized — opening text view.'),
                    ),
                  );
                  router.push('/document/${doc.id}/text');
                }
              },
            ),
            SheetAction(
              icon: Icons.slideshow_outlined,
              label: 'PowerPoint (.pptx) — Plus',
              onTap: () async {
                Navigator.of(context).pop();
                if (!ref.read(plusProvider).isActive) {
                  context.push('/paywall');
                  return;
                }
                await export.sharePowerPoint(doc);
              },
            ),
            SheetAction(
              icon: Icons.print_outlined,
              label: 'Print',
              onTap: () async {
                Navigator.of(context).pop();
                await export.printDocument(doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _merge(ScanDocument doc) async {
    final candidates = ref
        .read(activeDocumentsProvider)
        .where((d) => d.id != doc.id)
        .toList();
    if (candidates.isEmpty) {
      await AdaptiveDialog.confirm(
        context,
        title: 'Nothing to merge',
        message: 'Save another document first, then merge them here.',
        cancelLabel: 'OK',
        confirmLabel: 'Got it',
      );
      return;
    }
    if (!mounted) return;
    await AppBottomSheet.show<void>(
      context,
      title: 'Merge with…',
      scrollable: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: candidates.length,
          itemBuilder: (context, index) {
            final other = candidates[index];
            return DocumentRow(
              document: other,
              onShell: false,
              onLongPress: () {},
              onTap: () async {
                Navigator.of(context).pop();
                final merged = await ref
                    .read(viewerActionsProvider)
                    .merge(doc, other);
                Haptics.success();
                if (!mounted) return;
                this.context.pushReplacement('/document/${merged.id}');
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final doc = ref.watch(documentByIdProvider(widget.documentId));
    if (doc == null || doc.pages.isEmpty) {
      return Scaffold(backgroundColor: colors.paperBg);
    }
    final resolve = ref.watch(resolvePathProvider);
    final safePage = _page.clamp(0, doc.pageCount - 1);

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          style: PressStyle.dim,
          onTap: () => context.pop(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
            size: 20,
            semanticLabel: 'Back',
          ),
        ),
        title: PressableTap(
          style: PressStyle.dim,
          onTap: () => _rename(doc),
          child: Text(
            doc.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title(colors.textPrimary),
          ),
        ),
        actions: [
          PressableTap(
            style: PressStyle.dim,
            onTap: () => ref.read(exportServiceProvider).sharePdf(doc),
            child: Icon(
              Icons.ios_share_rounded,
              color: colors.textPrimary,
              semanticLabel: 'Share',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _ViewerMenu(
            onRename: () => _rename(doc),
            onMove: () => showMoveToFolder(context, ref, doc),
            onTools: () => context.push('/document/${doc.id}/tools'),
            onTrash: () => _trash(doc),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                // Let InteractiveViewer own the drag while a page is
                // zoomed so a one-finger pan doesn't flip pages.
                physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                onPageChanged: (index) => setState(() => _page = index),
                itemCount: doc.pageCount,
                itemBuilder: (context, index) {
                  final page = doc.pages[index];
                  final file = File(resolve(page.processedFileName));
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _ZoomablePage(
                      onZoomChanged: (zoomed) {
                        if (zoomed != _zoomed) {
                          setState(() => _zoomed = zoomed);
                        }
                      },
                      child: Center(
                        child: ClipRRect(
                          borderRadius: AppShapes.thumbnailRadius,
                          child: Image.file(
                            file,
                            // Key by mtime so a rewritten page file
                            // (e.g. after signing) repaints; a mounted
                            // Image ignores an equal FileImage even
                            // after the cache entry is evicted.
                            key: ValueKey(
                              '${page.id}:'
                              '${file.statSync().modified.microsecondsSinceEpoch}',
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Text(
              '${safePage + 1} / ${doc.pageCount}',
              style: AppTypography.mono(colors.textSecondary, size: 12),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ViewerToolbar(
              onExport: () => _export(doc),
              onSign: () => context.push('/document/${doc.id}/sign'),
              onText: () => context.push('/document/${doc.id}/text'),
              onMerge: () => _merge(doc),
              onAi: () => context.push('/document/${doc.id}/ai'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomablePage extends StatefulWidget {
  const _ZoomablePage({required this.onZoomChanged, required this.child});

  final ValueChanged<bool> onZoomChanged;
  final Widget child;

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> {
  final TransformationController _controller = TransformationController();
  bool _zoomed = false;

  void _handleTransform() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      widget.onZoomChanged(zoomed);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransform);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTransform);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      maxScale: 5,
      child: widget.child,
    );
  }
}

class _ViewerMenu extends StatelessWidget {
  const _ViewerMenu({
    required this.onRename,
    required this.onMove,
    required this.onTools,
    required this.onTrash,
  });

  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onTools;
  final VoidCallback onTrash;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.paperCard),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppShapes.cardRadius),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: onRename,
          child: Text(
            'Rename',
            style: AppTypography.bodyMedium(colors.textPrimary),
          ),
        ),
        MenuItemButton(
          onPressed: onMove,
          child: Text(
            'Move to folder',
            style: AppTypography.bodyMedium(colors.textPrimary),
          ),
        ),
        MenuItemButton(
          onPressed: onTools,
          child: Text(
            'Document tools',
            style: AppTypography.bodyMedium(colors.textPrimary),
          ),
        ),
        MenuItemButton(
          onPressed: onTrash,
          child: Text(
            'Move to Trash',
            style: AppTypography.bodyMedium(colors.danger),
          ),
        ),
      ],
      builder: (context, controller, _) => PressableTap(
        style: PressStyle.dim,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: Icon(
          Icons.more_horiz_rounded,
          color: colors.textPrimary,
          semanticLabel: 'More options',
        ),
      ),
    );
  }
}

class _ViewerToolbar extends StatelessWidget {
  const _ViewerToolbar({
    required this.onExport,
    required this.onSign,
    required this.onText,
    required this.onMerge,
    required this.onAi,
  });

  final VoidCallback onExport;
  final VoidCallback onSign;
  final VoidCallback onText;
  final VoidCallback onMerge;
  final VoidCallback onAi;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget tool(IconData icon, String label, VoidCallback onTap) =>
        PressableTap(
          onTap: onTap,
          child: SizedBox(
            width: 68,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: colors.textPrimary,
                  size: 22,
                  semanticLabel: label,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(label, style: AppTypography.label(colors.textSecondary)),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paperCard,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          tool(Icons.ios_share_rounded, 'Export', onExport),
          tool(Icons.draw_outlined, 'Sign', onSign),
          tool(Icons.notes_rounded, 'Text', onText),
          tool(Icons.merge_rounded, 'Merge', onMerge),
          tool(Icons.auto_awesome_rounded, 'AI', onAi),
        ],
      ),
    );
  }
}
