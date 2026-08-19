import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/app_bottom_sheet.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/folders_provider.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

/// Long-press actions for a library document.
Future<void> showDocumentActions(
  BuildContext context,
  WidgetRef ref,
  ScanDocument document,
) {
  return AppBottomSheet.show<void>(
    context,
    title: document.title,
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
            icon: Icons.drive_file_rename_outline_rounded,
            label: 'Rename',
            onTap: () async {
              Navigator.of(context).pop();
              final name = await AdaptiveDialog.prompt(
                context,
                title: 'Rename document',
                initialValue: document.title,
              );
              if (name != null) {
                await ref
                    .read(documentsProvider.notifier)
                    .rename(document.id, name);
              }
            },
          ),
          SheetAction(
            icon: Icons.folder_open_rounded,
            label: 'Move to folder',
            onTap: () async {
              Navigator.of(context).pop();
              await showMoveToFolder(context, ref, document);
            },
          ),
          SheetAction(
            icon: Icons.ios_share_rounded,
            label: 'Share',
            onTap: () async {
              Navigator.of(context).pop();
              await ref.read(exportServiceProvider).shareDefault(document);
            },
          ),
          SheetAction(
            icon: Icons.delete_outline_rounded,
            label: 'Move to Trash',
            destructive: true,
            onTap: () async {
              Navigator.of(context).pop();
              Haptics.destructive();
              await ref
                  .read(documentsProvider.notifier)
                  .moveToTrash(document.id);
            },
          ),
        ],
      ),
    ),
  );
}

/// Folder picker: Library root, each folder, or create a new one.
Future<void> showMoveToFolder(
  BuildContext context,
  WidgetRef ref,
  ScanDocument document,
) {
  final folders = ref.read(foldersProvider);
  return AppBottomSheet.show<void>(
    context,
    title: 'Move to',
    scrollable: true,
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
            icon: Icons.home_outlined,
            label: 'Library (no folder)',
            selected: document.folderId == null,
            onTap: () async {
              Navigator.of(context).pop();
              await ref
                  .read(documentsProvider.notifier)
                  .moveToFolder(document.id, null);
            },
          ),
          for (final folder in folders)
            SheetAction(
              icon: Icons.folder_outlined,
              label: folder.name,
              selected: document.folderId == folder.id,
              onTap: () async {
                Navigator.of(context).pop();
                await ref
                    .read(documentsProvider.notifier)
                    .moveToFolder(document.id, folder.id);
              },
            ),
          SheetAction(
            icon: Icons.create_new_folder_outlined,
            label: 'New folder…',
            onTap: () async {
              Navigator.of(context).pop();
              final name = await AdaptiveDialog.prompt(
                context,
                title: 'New folder',
                placeholder: 'Folder name',
                confirmLabel: 'Create',
              );
              if (name == null) return;
              final folder = await ref
                  .read(foldersProvider.notifier)
                  .create(name);
              await ref
                  .read(documentsProvider.notifier)
                  .moveToFolder(document.id, folder.id);
            },
          ),
        ],
      ),
    ),
  );
}

/// One row inside an action sheet.
class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.selected = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = destructive ? colors.danger : colors.textPrimary;
    return PressableTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22, semanticLabel: label),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(label, style: AppTypography.bodyMedium(color)),
            ),
            if (selected)
              Icon(
                Icons.check_rounded,
                color: colors.accent,
                size: 20,
                semanticLabel: 'Selected',
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
