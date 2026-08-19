import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/viewer/presentation/providers/viewer_actions_provider.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

class AdvancedDocumentToolsScreen extends ConsumerWidget {
  const AdvancedDocumentToolsScreen({super.key, required this.documentId});

  final String documentId;

  Future<void> _extract(BuildContext context, WidgetRef ref) async {
    final doc = ref.read(documentByIdProvider(documentId));
    if (doc == null) return;
    final selected = <int>{};
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Extract pages'),
          content: SizedBox(
            width: 360,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: doc.pageCount,
              itemBuilder: (context, index) => CheckboxListTile(
                value: selected.contains(index),
                // The scheme's `primary` is the deep indigo shell colour, so a
                // ticked box would read as dark-on-dark in the dark theme (and
                // `onPrimary` is not overridden alongside it, so the tick has
                // no guaranteed contrast either). Selection uses the accent.
                activeColor: context.colors.accent,
                checkColor: Colors.white,
                title: Text('Page ${index + 1}'),
                onChanged: (value) => setDialogState(() {
                  value == true ? selected.add(index) : selected.remove(index);
                }),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Extract'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !context.mounted) return;
    final extracted = await ref
        .read(viewerActionsProvider)
        .extractPages(doc, selected);
    if (context.mounted) {
      context.pushReplacement('/document/${extracted.id}');
    }
  }

  Future<void> _compress(BuildContext context, WidgetRef ref) async {
    final doc = ref.read(documentByIdProvider(documentId));
    if (doc == null) return;
    final level = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      // The app's bottomSheetTheme is transparent because AppBottomSheet
      // paints its own paper container; a raw sheet has to supply one or it
      // renders straight onto the dimmed backdrop with no surface at all.
      backgroundColor: context.colors.paperCard,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Compress PDF'),
              subtitle: Text('The original scan is never changed.'),
            ),
            for (final option in const [
              ('low', 'Low compression', 'Best image quality'),
              ('medium', 'Medium compression', 'Balanced size and quality'),
              ('high', 'High compression', 'Smallest file'),
            ])
              ListTile(
                title: Text(option.$2),
                subtitle: Text(option.$3),
                onTap: () => Navigator.pop(context, option.$1),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (level == null) return;
    await ref.read(exportServiceProvider).shareCompressedPdf(doc, level: level);
  }

  Future<void> _watermark(BuildContext context, WidgetRef ref) async {
    final doc = ref.read(documentByIdProvider(documentId));
    if (doc == null) return;
    final textController = TextEditingController(text: 'CONFIDENTIAL');
    final firstController = TextEditingController(text: '1');
    final lastController = TextEditingController(text: '${doc.pageCount}');
    var opacity = 0.25;
    var position = 'center';
    var repeat = false;
    Uint8List? imageBytes;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // See _compress: the theme's sheet background is transparent by design.
      backgroundColor: context.colors.paperCard,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Watermark',
                  style: AppTypography.title(context.colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: textController,
                  enabled: imageBytes == null,
                  decoration: const InputDecoration(
                    labelText: 'Watermark text',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (imageBytes != null) {
                      setSheetState(() => imageBytes = null);
                      return;
                    }
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setSheetState(() => imageBytes = bytes);
                    }
                  },
                  icon: Icon(
                    imageBytes == null ? Icons.image_outlined : Icons.close,
                  ),
                  label: Text(
                    imageBytes == null
                        ? 'Use image watermark'
                        : 'Remove image watermark',
                  ),
                ),
                Text('Opacity ${(opacity * 100).round()}%'),
                Slider(
                  value: opacity,
                  min: 0.05,
                  max: 0.8,
                  // Defaults to the scheme's deep indigo `primary`, which is
                  // invisible against the dark-theme paper card.
                  activeColor: context.colors.accent,
                  inactiveColor: context.colors.hairline,
                  onChanged: (value) => setSheetState(() => opacity = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: position,
                  decoration: const InputDecoration(labelText: 'Position'),
                  items: const [
                    DropdownMenuItem(value: 'top', child: Text('Top')),
                    DropdownMenuItem(value: 'center', child: Text('Center')),
                    DropdownMenuItem(value: 'bottom', child: Text('Bottom')),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => position = value ?? 'center'),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: repeat,
                  title: const Text('Repeat across each page'),
                  onChanged: (value) => setSheetState(() => repeat = value),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: firstController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'First page',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: lastController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Last page',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: const Text('Create and share PDF'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (accepted == true) {
      final first = ((int.tryParse(firstController.text) ?? 1) - 1).clamp(
        0,
        doc.pageCount - 1,
      );
      final last = ((int.tryParse(lastController.text) ?? doc.pageCount) - 1)
          .clamp(first, doc.pageCount - 1);
      await ref
          .read(exportServiceProvider)
          .shareWatermarkedPdf(
            doc,
            text: textController.text,
            imageBytes: imageBytes,
            opacity: opacity,
            position: position,
            repeat: repeat,
            firstPage: first,
            lastPage: last,
          );
    }
    textController.dispose();
    firstController.dispose();
    lastController.dispose();
  }

  Future<void> _lock(BuildContext context, WidgetRef ref) async {
    final doc = ref.read(documentByIdProvider(documentId));
    if (doc == null) return;
    final password = TextEditingController();
    final confirmation = TextEditingController();
    String? error;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lock PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: confirmation,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    error!,
                    style: TextStyle(color: context.colors.danger),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (password.text.length < 4) {
                  setDialogState(() => error = 'Use at least 4 characters.');
                } else if (password.text != confirmation.text) {
                  setDialogState(() => error = 'Passwords do not match.');
                } else {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Create locked PDF'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      await ref
          .read(exportServiceProvider)
          .shareLockedPdf(doc, password: password.text);
    }
    password.dispose();
    confirmation.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final doc = ref.watch(documentByIdProvider(documentId));
    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          onTap: () => context.pop(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
        ),
        title: Text(
          'Document Tools',
          style: AppTypography.title(colors.textPrimary),
        ),
      ),
      body: doc == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _Action(
                  icon: Icons.view_carousel_outlined,
                  title: 'Manage Pages',
                  subtitle: 'Add, reorder, delete, or duplicate pages.',
                  onTap: () => context.push('/document/$documentId/pages'),
                ),
                _Action(
                  icon: Icons.content_cut_rounded,
                  title: 'Extract Pages',
                  subtitle: 'Create a new document from selected pages.',
                  onTap: () => _extract(context, ref),
                ),
                _Action(
                  icon: Icons.compress_rounded,
                  title: 'Compress PDF',
                  subtitle: 'Share a low, medium, or high compression copy.',
                  onTap: () => _compress(context, ref),
                ),
                _Action(
                  icon: Icons.branding_watermark_outlined,
                  title: 'Add Watermark',
                  subtitle:
                      'Text or image, position, opacity, repeat, and page range.',
                  onTap: () => _watermark(context, ref),
                ),
                _Action(
                  icon: Icons.lock_outline_rounded,
                  title: 'Lock PDF',
                  subtitle: 'Create an encrypted PDF with a password.',
                  onTap: () => _lock(context, ref),
                ),
              ],
            ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}
