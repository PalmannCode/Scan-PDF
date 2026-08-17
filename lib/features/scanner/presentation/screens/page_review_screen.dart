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
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_session_provider.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/scanner/presentation/widgets/camera_controls.dart';
import 'package:scanpdf/features/scanner/presentation/widgets/filter_preview.dart';
import 'package:scanpdf/features/scanner/presentation/widgets/save_document_sheet.dart';

/// After-capture review (Jira §14): crop, rotate, filter, delete, add,
/// reorder, save.
class PageReviewScreen extends ConsumerStatefulWidget {
  const PageReviewScreen({super.key});

  @override
  ConsumerState<PageReviewScreen> createState() => _PageReviewScreenState();
}

class _PageReviewScreenState extends ConsumerState<PageReviewScreen> {
  late final PageController _pageController = PageController();
  int _current = 0;
  bool _showFilters = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _current = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _discard() async {
    final ok = await AdaptiveDialog.confirm(
      context,
      title: 'Discard scans?',
      message: 'All captured pages will be discarded.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!ok || !mounted) return;
    ref.read(scanSessionProvider.notifier).clear();
    context.go('/');
  }

  void _deleteCurrent() {
    final session = ref.read(scanSessionProvider);
    if (session.pages.length == 1) {
      _discard();
      return;
    }
    Haptics.destructive();
    ref.read(scanSessionProvider.notifier).removePage(_current);
    setState(
      () => _current = _current.clamp(
        0,
        ref.read(scanSessionProvider).pages.length - 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final session = ref.watch(scanSessionProvider);
    if (session.pages.isEmpty) {
      // Session was cleared (saved or discarded) — nothing to review.
      return Scaffold(backgroundColor: colors.paperBg);
    }
    final safeIndex = _current.clamp(0, session.pages.length - 1);
    final page = session.pages[safeIndex];

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          style: PressStyle.dim,
          onTap: _discard,
          child: Icon(
            Icons.close_rounded,
            color: colors.textPrimary,
            semanticLabel: 'Discard',
          ),
        ),
        title: Text(
          '${safeIndex + 1} / ${session.pages.length}',
          style: AppTypography.mono(colors.textPrimary, size: 15),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: PressableTap(
              onTap: () => showSaveDocumentSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: AppShapes.pillRadius,
                ),
                child: Text(
                  'Save',
                  style: AppTypography.bodyMedium(Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _current = index),
                itemCount: session.pages.length,
                itemBuilder: (context, index) {
                  final p = session.pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: p.rotationQuarters,
                        child: FilterPreview(
                          filter: p.filter,
                          child: ClipRRect(
                            borderRadius: AppShapes.thumbnailRadius,
                            child: Image.file(
                              File(p.tempPath),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showFilters)
              FilterChipsRow(
                selected: page.filter,
                onSelected: (f) {
                  if (f.isPlus && !ref.read(plusProvider).isActive) {
                    context.push('/paywall');
                    return;
                  }
                  ref
                      .read(scanSessionProvider.notifier)
                      .updatePage(safeIndex, page.copyWith(filter: f));
                  setState(() => _showFilters = false);
                },
              ),
            _ThumbStrip(current: safeIndex, onSelect: _select),
            _ReviewToolbar(
              onCrop: () => context.push('/crop/$safeIndex'),
              onRotate: () => ref
                  .read(scanSessionProvider.notifier)
                  .updatePage(
                    safeIndex,
                    page.copyWith(
                      rotationQuarters: (page.rotationQuarters + 1) % 4,
                    ),
                  ),
              onFilter: () => setState(() => _showFilters = !_showFilters),
              onDelete: _deleteCurrent,
              onAddPage: () => context.push('/camera'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbStrip extends ConsumerWidget {
  const _ThumbStrip({required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final pages = ref.watch(scanSessionProvider).pages;
    return SizedBox(
      height: 76,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        onReorder: (from, to) {
          if (to > from) to--;
          ref.read(scanSessionProvider.notifier).reorder(from, to);
          Haptics.selection();
          onSelect(to);
        },
        itemCount: pages.length,
        proxyDecorator: (child, _, _) => child,
        itemBuilder: (context, index) {
          final page = pages[index];
          final active = index == current;
          return Padding(
            key: ValueKey(page.tempPath),
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: PressableTap(
              onTap: () => onSelect(index),
              child: Container(
                width: 52,
                decoration: BoxDecoration(
                  borderRadius: AppShapes.thumbnailRadius,
                  border: Border.all(
                    color: active ? colors.accent : colors.hairline,
                    width: active ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(
                  File(page.tempPath),
                  fit: BoxFit.cover,
                  cacheWidth: 150,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewToolbar extends StatelessWidget {
  const _ReviewToolbar({
    required this.onCrop,
    required this.onRotate,
    required this.onFilter,
    required this.onDelete,
    required this.onAddPage,
  });

  final VoidCallback onCrop;
  final VoidCallback onRotate;
  final VoidCallback onFilter;
  final VoidCallback onDelete;
  final VoidCallback onAddPage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget tool(
      IconData icon,
      String label,
      VoidCallback onTap, {
      bool destructive = false,
    }) {
      final color = destructive ? colors.danger : colors.textPrimary;
      return PressableTap(
        onTap: onTap,
        child: SizedBox(
          width: 62,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22, semanticLabel: label),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: AppTypography.label(color)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paperCard,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          tool(Icons.crop_rounded, 'Crop', onCrop),
          tool(Icons.rotate_90_degrees_ccw_rounded, 'Rotate', onRotate),
          tool(Icons.auto_awesome_rounded, 'Filter', onFilter),
          tool(Icons.add_a_photo_outlined, 'Add', onAddPage),
          tool(
            Icons.delete_outline_rounded,
            'Delete',
            onDelete,
            destructive: true,
          ),
        ],
      ),
    );
  }
}
