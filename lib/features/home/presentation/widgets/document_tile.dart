import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

String _meta(ScanDocument doc) =>
    '${DateFormat('d MMM').format(doc.createdAt)} · ${doc.pageCount} pg';

/// Page thumbnail with the app's folded-corner sheet treatment.
class DocumentThumbnail extends ConsumerWidget {
  const DocumentThumbnail({super.key, required this.document, this.width});

  final ScanDocument document;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final resolve = ref.watch(resolvePathProvider);
    final fileName = document.thumbnailFileName;
    return Container(
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: AppShapes.thumbnailRadius,
        border: Border.all(color: colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: fileName == null
          ? Icon(Icons.description_outlined,
              color: colors.textSecondary, size: 28)
          : Image.file(
              File(resolve(fileName)),
              fit: BoxFit.cover,
              cacheWidth: 500,
              errorBuilder: (context, _, _) => Icon(
                Icons.description_outlined,
                color: colors.textSecondary,
                size: 28,
              ),
            ),
    );
  }
}

/// Grid card for the library.
class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.onTap,
    required this.onLongPress,
  });

  final ScanDocument document;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressableTap(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: DocumentThumbnail(document: document),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            document.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium(colors.onShell),
          ),
          const SizedBox(height: 2),
          Text(
            _meta(document),
            style: AppTypography.mono(colors.onShellMuted, size: 11),
          ),
        ],
      ),
    );
  }
}

/// List row for the library.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    super.key,
    required this.document,
    required this.onTap,
    required this.onLongPress,
    this.onShell = true,
  });

  final ScanDocument document;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool onShell;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titleColor = onShell ? colors.onShell : colors.textPrimary;
    final metaColor = onShell ? colors.onShellMuted : colors.textSecondary;
    return PressableTap(
      onTap: onTap,
      onLongPress: onLongPress,
      style: onShell ? PressStyle.dim : PressStyle.scale,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 60,
              child: DocumentThumbnail(document: document),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium(titleColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _meta(document),
                    style: AppTypography.mono(metaColor, size: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: metaColor, semanticLabel: 'Open'),
          ],
        ),
      ),
    );
  }
}
