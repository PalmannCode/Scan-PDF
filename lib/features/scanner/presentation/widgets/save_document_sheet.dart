import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/app_bottom_sheet.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/home/presentation/providers/folders_provider.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_saver_provider.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_session_provider.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';

/// Save flow (Jira §15): document name + destination folder. Documents
/// are stored page-based and PDF-ready; export formats live in the
/// viewer and Tools.
Future<void> showSaveDocumentSheet(BuildContext context, WidgetRef ref) {
  return AppBottomSheet.show<void>(
    context,
    title: 'Save document',
    child: const _SaveSheetBody(),
  );
}

class _SaveSheetBody extends ConsumerStatefulWidget {
  const _SaveSheetBody();

  @override
  ConsumerState<_SaveSheetBody> createState() => _SaveSheetBodyState();
}

class _SaveSheetBodyState extends ConsumerState<_SaveSheetBody> {
  late final TextEditingController _nameController;
  String? _folderId;
  bool _saving = false;
  int _done = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    final pattern = ref.read(settingsProvider).defaultFileNameFormat;
    String name;
    try {
      name = DateFormat(pattern).format(DateTime.now());
    } catch (_) {
      name = 'Scan ${DateFormat('yyyy-MM-dd HH.mm').format(DateTime.now())}';
    }
    _nameController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _nameController.text.trim();
    if (title.isEmpty || _saving) return;
    final fromEvent = ref.read(scanSessionProvider).fromEvent;
    setState(() {
      _saving = true;
      _total = ref.read(scanSessionProvider).pages.length;
    });
    try {
      await ref
          .read(scanSaverProvider)
          .saveSession(
            title: title,
            folderId: _folderId,
            onProgress: (done, total) {
              if (mounted) {
                setState(() {
                  _done = done;
                  _total = total;
                });
              }
            },
          );
      Haptics.success();
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go(fromEvent ? '/event' : '/');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      await AdaptiveDialog.confirm(
        context,
        title: 'Could not save',
        message: 'Processing failed. Please try again.',
        cancelLabel: 'OK',
        confirmLabel: 'Retry',
      ).then((retry) {
        if (retry) _save();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final folders = ref.watch(foldersProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Name', style: AppTypography.label(colors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.toolCard,
              borderRadius: AppShapes.buttonRadius,
            ),
            child: TextField(
              controller: _nameController,
              style: AppTypography.body(colors.textPrimary),
              cursorColor: colors.accent,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Folder', style: AppTypography.label(colors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _FolderChip(
                label: 'Library',
                selected: _folderId == null,
                onTap: () => setState(() => _folderId = null),
              ),
              for (final folder in folders)
                _FolderChip(
                  label: folder.name,
                  selected: _folderId == folder.id,
                  onTap: () => setState(() => _folderId = folder.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          PressableTap(
            onTap: _saving ? null : _save,
            enabled: !_saving,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: _saving
                    ? colors.accent.withValues(alpha: 0.55)
                    : colors.accent,
                borderRadius: AppShapes.buttonRadius,
              ),
              child: Text(
                _saving ? 'Processing $_done / $_total…' : 'Save to library',
                textAlign: TextAlign.center,
                style: AppTypography.title(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Saved as a PDF-ready document. Export to PDF, image, or text any time.',
            textAlign: TextAlign.center,
            style: AppTypography.caption(colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressableTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.accent : colors.toolCard,
          borderRadius: AppShapes.pillRadius,
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium(
            selected ? Colors.white : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
