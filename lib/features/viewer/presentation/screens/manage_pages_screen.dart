import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/viewer/presentation/providers/viewer_actions_provider.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

class ManagePagesScreen extends ConsumerStatefulWidget {
  const ManagePagesScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<ManagePagesScreen> createState() => _ManagePagesScreenState();
}

class _ManagePagesScreenState extends ConsumerState<ManagePagesScreen> {
  bool _working = false;

  Future<void> _addPages() async {
    final doc = ref.read(documentByIdProvider(widget.documentId));
    if (doc == null || _working) return;
    final images = await ImagePicker().pickMultiImage();
    if (images.isEmpty) return;
    setState(() => _working = true);
    try {
      await ref
          .read(viewerActionsProvider)
          .appendImagePages(doc, images.map((image) => image.path));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _delete(int index) async {
    final doc = ref.read(documentByIdProvider(widget.documentId));
    if (doc == null) return;
    if (doc.pageCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A document must keep one page.')),
      );
      return;
    }
    final confirmed = await AdaptiveDialog.confirm(
      context,
      title: 'Delete page ${index + 1}?',
      message: 'This removes the page from this document permanently.',
      confirmLabel: 'Delete page',
      destructive: true,
    );
    if (confirmed) {
      await ref.read(viewerActionsProvider).deletePage(doc, index);
    }
  }

  Future<void> _duplicate() async {
    final doc = ref.read(documentByIdProvider(widget.documentId));
    if (doc == null || _working) return;
    setState(() => _working = true);
    try {
      final duplicate = await ref.read(viewerActionsProvider).duplicate(doc);
      if (mounted) context.pushReplacement('/document/${duplicate.id}');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final doc = ref.watch(documentByIdProvider(widget.documentId));
    final resolve = ref.watch(resolvePathProvider);
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
          'Manage Pages',
          style: AppTypography.title(colors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: _working ? null : _addPages,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Add pages',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: doc == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Drag pages into order. Add photos or remove individual pages.',
                    style: AppTypography.body(colors.textSecondary),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: doc.pageCount,
                    onReorder: (from, to) async {
                      if (to > from) to--;
                      await ref
                          .read(viewerActionsProvider)
                          .reorderPages(doc, from, to);
                    },
                    itemBuilder: (context, index) {
                      final page = doc.pages[index];
                      return Card(
                        key: ValueKey(page.id),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(resolve(page.processedFileName)),
                              width: 46,
                              height: 58,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text('Page ${index + 1}'),
                          subtitle: Text(
                            page.hasOcr ? 'Text recognized' : 'No OCR text',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _delete(index),
                                icon: const Icon(Icons.delete_outline_rounded),
                                tooltip: 'Delete page',
                              ),
                              const Icon(Icons.drag_handle_rounded),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _working ? null : _duplicate,
                            icon: const Icon(Icons.copy_all_outlined),
                            label: const Text('Duplicate'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _working ? null : _addPages,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(_working ? 'Adding…' : 'Add Pages'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
