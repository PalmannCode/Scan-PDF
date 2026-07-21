import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/app_background.dart';
import 'package:scanpdf/core/widgets/empty_state.dart';
import 'package:scanpdf/core/widgets/paper_sheet_illustration.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/core/widgets/staggered_column.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/home/presentation/widgets/document_tile.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  Future<void> _emptyTrash(BuildContext context, WidgetRef ref) async {
    final ok = await AdaptiveDialog.confirm(
      context,
      title: 'Empty trash?',
      message:
          'All documents in the trash will be deleted permanently. This cannot be undone.',
      confirmLabel: 'Empty',
      destructive: true,
    );
    if (ok) await ref.read(documentsProvider.notifier).emptyTrash();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final trashed = ref.watch(trashedDocumentsProvider);

    return Scaffold(
      backgroundColor: colors.shellBg,
      body: AppBackground(
        treatment: BackgroundTreatment.shell,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    PressableTap(
                      style: PressStyle.dim,
                      onTap: () => context.pop(),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: colors.onShell,
                          size: 20,
                          semanticLabel: 'Back'),
                    ),
                    Expanded(
                      child: Text(
                        'Trash Bin',
                        textAlign: TextAlign.center,
                        style: AppTypography.headline(colors.onShell),
                      ),
                    ),
                    PressableTap(
                      style: PressStyle.dim,
                      enabled: trashed.isNotEmpty,
                      onTap: trashed.isEmpty
                          ? null
                          : () => _emptyTrash(context, ref),
                      child: Text(
                        'Empty',
                        style: AppTypography.bodyMedium(
                          trashed.isEmpty
                              ? colors.onShellMuted
                              : colors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: trashed.isEmpty
                    ? const EmptyState(
                        onShell: true,
                        illustration: PaperSheetIllustration(size: 110),
                        title: 'Trash is empty',
                        subtitle:
                            'Deleted documents land here before they are gone for good.',
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        itemCount: trashed.length,
                        itemBuilder: (context, index) {
                          final doc = trashed[index];
                          return _TrashRow(doc: doc, index: index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrashRow extends ConsumerWidget {
  const _TrashRow({required this.doc, required this.index});

  final dynamic doc;
  final int index;

  Future<void> _deleteForever(BuildContext context, WidgetRef ref) async {
    final ok = await AdaptiveDialog.confirm(
      context,
      title: 'Delete permanently?',
      message: '"${doc.title}" will be gone for good.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) {
      await ref.read(documentsProvider.notifier).deletePermanent(doc.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 56,
            child: DocumentThumbnail(document: doc),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium(colors.onShell),
                ),
                const SizedBox(height: 2),
                Text(
                  'Deleted ${DateFormat('d MMM').format(doc.deletedAt ?? doc.modifiedAt)}',
                  style:
                      AppTypography.mono(colors.onShellMuted, size: 11),
                ),
              ],
            ),
          ),
          PressableTap(
            style: PressStyle.dim,
            onTap: () =>
                ref.read(documentsProvider.notifier).restore(doc.id),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(Icons.restore_rounded,
                  color: colors.onShell, semanticLabel: 'Restore'),
            ),
          ),
          PressableTap(
            style: PressStyle.dim,
            onTap: () => _deleteForever(context, ref),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(Icons.delete_forever_rounded,
                  color: colors.danger,
                  semanticLabel: 'Delete permanently'),
            ),
          ),
        ],
      ),
    ).staggered(index);
  }
}
