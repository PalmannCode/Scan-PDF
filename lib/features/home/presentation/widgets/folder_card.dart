import 'package:flutter/material.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/shared/models/scan_folder.dart';

class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.folder,
    required this.documentCount,
    required this.onTap,
    this.onLongPress,
  });

  final ScanFolder folder;
  final int documentCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressableTap(
      style: PressStyle.dim,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.shellElevated,
          borderRadius: AppShapes.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.folder_rounded,
              color: colors.accent,
              size: 26,
              semanticLabel: 'Folder ${folder.name}',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium(colors.onShell),
            ),
            const SizedBox(height: 2),
            Text(
              '$documentCount items',
              style: AppTypography.mono(colors.onShellMuted, size: 11),
            ),
          ],
        ),
      ),
    );
  }
}
