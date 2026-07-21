import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/responsive.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/app_background.dart';
import 'package:scanpdf/core/widgets/empty_state.dart';
import 'package:scanpdf/core/widgets/paper_sheet_illustration.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/core/widgets/staggered_column.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/folders_provider.dart';
import 'package:scanpdf/features/home/presentation/widgets/document_actions.dart';
import 'package:scanpdf/features/home/presentation/widgets/document_tile.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/shared/models/enums.dart';

class FolderScreen extends ConsumerWidget {
  const FolderScreen({super.key, required this.folderId});

  final String folderId;

  Future<void> _folderMenu(BuildContext context, WidgetRef ref) async {
    final folders = ref.read(foldersProvider.notifier);
    final folder = ref.read(folderByIdProvider(folderId));
    if (folder == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FolderMenuSheet(name: folder.name),
    );
    if (action == 'rename' && context.mounted) {
      final name = await AdaptiveDialog.prompt(
        context,
        title: 'Rename folder',
        initialValue: folder.name,
      );
      if (name != null) await folders.rename(folderId, name);
    } else if (action == 'delete' && context.mounted) {
      final ok = await AdaptiveDialog.confirm(
        context,
        title: 'Delete folder?',
        message:
            'Documents inside will move back to the library. This cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true,
      );
      if (ok) {
        await folders.delete(folderId);
        if (context.mounted) context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final folder = ref.watch(folderByIdProvider(folderId));
    final docs = sortDocuments(
      ref
          .watch(activeDocumentsProvider)
          .where((d) => d.folderId == folderId)
          .toList(),
      ref.watch(settingsProvider).sortMode,
    );
    final viewMode =
        ref.watch(settingsProvider.select((s) => s.viewMode));

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
                        folder?.name ?? 'Folder',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headline(colors.onShell),
                      ),
                    ),
                    PressableTap(
                      style: PressStyle.dim,
                      onTap: () => _folderMenu(context, ref),
                      child: Icon(Icons.more_horiz_rounded,
                          color: colors.onShell,
                          semanticLabel: 'Folder options'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const EmptyState(
                        onShell: true,
                        illustration: PaperSheetIllustration(size: 110),
                        title: 'Folder is empty',
                        subtitle:
                            'Move documents here from the library, or scan something new.',
                      )
                    : _FolderDocs(docs: docs, viewMode: viewMode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderDocs extends ConsumerWidget {
  const _FolderDocs({required this.docs, required this.viewMode});

  final List docs;
  final LibraryViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (viewMode == LibraryViewMode.list) {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          return DocumentRow(
            document: doc,
            onTap: () => context.push('/document/${doc.id}'),
            onLongPress: () => showDocumentActions(context, ref, doc),
          ).staggered(index);
        },
      );
    }
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.gridColumns(context),
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.68,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return DocumentTile(
          document: doc,
          onTap: () => context.push('/document/${doc.id}'),
          onLongPress: () => showDocumentActions(context, ref, doc),
        ).staggered(index);
      },
    );
  }
}

class _FolderMenuSheet extends StatelessWidget {
  const _FolderMenuSheet({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetAction(
            icon: Icons.drive_file_rename_outline_rounded,
            label: 'Rename folder',
            onTap: () => Navigator.of(context).pop('rename'),
          ),
          SheetAction(
            icon: Icons.delete_outline_rounded,
            label: 'Delete folder',
            destructive: true,
            onTap: () => Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    );
  }
}
