import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/app_bottom_sheet.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/import_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/folders_provider.dart';
import 'package:scanpdf/features/home/presentation/widgets/document_tile.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_session_provider.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';

/// The Tools bottom sheet (Jira §12), including the complete V2 tool set.
abstract class ToolsSheet {
  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      title: 'Tools',
      scrollable: true,
      child: const _ToolsBody(),
    );
  }
}

class _ToolsBody extends ConsumerWidget {
  const _ToolsBody();

  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Future<void> _withDocument(
    BuildContext context,
    WidgetRef ref,
    String title,
    Future<void> Function(ScanDocument doc) action,
  ) async {
    Navigator.of(context).pop();
    final doc = await pickDocument(context, ref, title: title);
    if (doc != null) await action(doc);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final export = ref.read(exportServiceProvider);

    List<Widget> section(String name, List<_Tool> tools) => [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.sm,
        ),
        child: Text(
          name,
          style: AppTypography.label(context.colors.textSecondary),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [for (final tool in tools) _ToolCard(tool: tool)],
        ),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...section('SCAN', [
          _Tool(
            icon: Icons.document_scanner_outlined,
            label: 'Document',
            onTap: () => _closeThen(context, () {
              ref
                  .read(scanSessionProvider.notifier)
                  .start(mode: CameraMode.document);
              context.push('/camera');
            }),
          ),
          _Tool(
            icon: Icons.text_fields_rounded,
            label: 'Text',
            onTap: () => _closeThen(context, () {
              ref
                  .read(scanSessionProvider.notifier)
                  .start(mode: CameraMode.text);
              context.push('/camera');
            }),
          ),
          _Tool(
            icon: Icons.menu_book_outlined,
            label: 'Book',
            badge: 'PLUS',
            onTap: () {
              if (!ref.read(plusProvider).isActive) {
                _closeThen(context, () => context.push('/paywall'));
                return;
              }
              _closeThen(context, () {
                ref
                    .read(scanSessionProvider.notifier)
                    .start(mode: CameraMode.book);
                context.push('/camera');
              });
            },
          ),
          _Tool(
            icon: Icons.qr_code_scanner_rounded,
            label: 'QR Code',
            onTap: () => _closeThen(context, () {
              ref
                  .read(scanSessionProvider.notifier)
                  .start(mode: CameraMode.qrCode);
              context.push('/camera');
            }),
          ),
          _Tool(
            icon: Icons.translate_rounded,
            label: 'Translate',
            badge: 'PLUS',
            onTap: () {
              if (!ref.read(plusProvider).isActive) {
                _closeThen(context, () => context.push('/paywall'));
                return;
              }
              _closeThen(context, () {
                ref
                    .read(scanSessionProvider.notifier)
                    .start(mode: CameraMode.translate);
                context.push('/camera');
              });
            },
          ),
        ]),
        ...section('CREATE', [
          _Tool(
            icon: Icons.create_new_folder_outlined,
            label: 'Folder',
            onTap: () async {
              Navigator.of(context).pop();
              final name = await AdaptiveDialog.prompt(
                context,
                title: 'New folder',
                placeholder: 'Folder name',
                confirmLabel: 'Create',
              );
              if (name != null && name.trim().isNotEmpty) {
                await ref.read(foldersProvider.notifier).create(name.trim());
              }
            },
          ),
          _Tool(
            icon: Icons.receipt_long_outlined,
            label: 'Expenses',
            badge: 'PLUS',
            onTap: () {
              if (!ref.read(plusProvider).isActive) {
                _closeThen(context, () => context.push('/paywall'));
                return;
              }
              _closeThen(context, () => context.push('/expense-report'));
            },
          ),
        ]),
        ...section('IMPORT', [
          _Tool(
            icon: Icons.photo_library_outlined,
            label: 'Photos',
            onTap: () => _closeThen(context, () async {
              final added = await ref
                  .read(importControllerProvider)
                  .importPhotos();
              if (added > 0 && context.mounted) {
                context.push('/review');
              }
            }),
          ),
          _Tool(
            icon: Icons.folder_open_outlined,
            label: 'Files',
            onTap: () => _closeThen(context, () async {
              final added = await ref
                  .read(importControllerProvider)
                  .importFiles();
              if (added > 0 && context.mounted) {
                context.push('/review');
              }
            }),
          ),
        ]),
        ...section('EXPORT', [
          _Tool(
            icon: Icons.picture_as_pdf_outlined,
            label: 'To PDF',
            onTap: () =>
                _withDocument(context, ref, 'Export to PDF', export.sharePdf),
          ),
          _Tool(
            icon: Icons.image_outlined,
            label: 'To Image',
            onTap: () => _withDocument(
              context,
              ref,
              'Export to images',
              (doc) => export.shareImages(doc, ExportFormat.jpg),
            ),
          ),
          _Tool(
            icon: Icons.notes_rounded,
            label: 'To Text',
            onTap: () => _withDocument(context, ref, 'Export recognized text', (
              doc,
            ) async {
              if (doc.hasOcr) {
                await export.shareTxt(doc);
              } else if (context.mounted) {
                context.push('/document/${doc.id}/text');
              }
            }),
          ),
          _Tool(
            icon: Icons.description_outlined,
            label: 'To Word',
            badge: 'PLUS',
            onTap: () {
              if (!ref.read(plusProvider).isActive) {
                _closeThen(context, () => context.push('/paywall'));
                return;
              }
              _withDocument(context, ref, 'Export to Word', export.shareWord);
            },
          ),
          _Tool(
            icon: Icons.slideshow_outlined,
            label: 'To PPT',
            badge: 'PLUS',
            onTap: () {
              if (!ref.read(plusProvider).isActive) {
                _closeThen(context, () => context.push('/paywall'));
                return;
              }
              _withDocument(
                context,
                ref,
                'Export to PowerPoint',
                export.sharePowerPoint,
              );
            },
          ),
        ]),
        ...section('EDIT', [
          _Tool(
            icon: Icons.draw_outlined,
            label: 'Sign',
            onTap: () =>
                _withDocument(context, ref, 'Sign a document', (doc) async {
                  if (context.mounted) {
                    context.push('/document/${doc.id}/sign');
                  }
                }),
          ),
          _Tool(
            icon: Icons.merge_rounded,
            label: 'Merge',
            onTap: () =>
                _withDocument(context, ref, 'Merge documents', (doc) async {
                  if (context.mounted) {
                    context.push('/document/${doc.id}');
                  }
                }),
          ),
          _Tool(
            icon: Icons.content_cut_rounded,
            label: 'Extract',
            onTap: () =>
                _withDocument(context, ref, 'Extract pages from…', (doc) async {
                  if (context.mounted) {
                    context.push('/document/${doc.id}/tools');
                  }
                }),
          ),
          _Tool(
            icon: Icons.reorder_rounded,
            label: 'Reorder',
            onTap: () =>
                _withDocument(context, ref, 'Reorder pages in…', (doc) async {
                  if (context.mounted) {
                    context.push('/document/${doc.id}/pages');
                  }
                }),
          ),
          _Tool(
            icon: Icons.compress_rounded,
            label: 'Compress',
            onTap: () => _withDocument(context, ref, 'Compress…', (doc) async {
              if (context.mounted) {
                context.push('/document/${doc.id}/tools');
              }
            }),
          ),
          _Tool(
            icon: Icons.branding_watermark_outlined,
            label: 'Watermark',
            onTap: () => _withDocument(context, ref, 'Watermark…', (doc) async {
              if (context.mounted) {
                context.push('/document/${doc.id}/tools');
              }
            }),
          ),
          _Tool(
            icon: Icons.lock_outline_rounded,
            label: 'Lock PDF',
            onTap: () => _withDocument(context, ref, 'Lock…', (doc) async {
              if (context.mounted) {
                context.push('/document/${doc.id}/tools');
              }
            }),
          ),
        ]),
        ...section('UTILITIES', [
          _Tool(
            icon: Icons.print_outlined,
            label: 'Print',
            onTap: () => _withDocument(
              context,
              ref,
              'Print a document',
              export.printDocument,
            ),
          ),
          _Tool(
            icon: Icons.straighten_rounded,
            label: 'Measure',
            onTap: () => _closeThen(context, () {
              ref
                  .read(scanSessionProvider.notifier)
                  .start(mode: CameraMode.measure);
              context.push('/camera');
            }),
          ),
          _Tool(
            icon: Icons.calculate_outlined,
            label: 'Count',
            onTap: () => _closeThen(context, () {
              ref
                  .read(scanSessionProvider.notifier)
                  .start(mode: CameraMode.count);
              context.push('/camera');
            }),
          ),
          _Tool(
            icon: Icons.route_rounded,
            label: 'Workflows',
            badge: 'PLUS',
            onTap: () {
              if (!ref.read(plusProvider).isActive) {
                _closeThen(context, () => context.push('/paywall'));
                return;
              }
              _closeThen(context, () => context.push('/settings/workflows'));
            },
          ),
        ]),
        ...section('AI', [
          _Tool(
            icon: Icons.question_answer_outlined,
            label: 'Ask AI',
            onTap: () =>
                _withDocument(context, ref, 'Ask AI about…', (doc) async {
                  if (context.mounted) context.push('/document/${doc.id}/ai');
                }),
          ),
          _Tool(
            icon: Icons.summarize_outlined,
            label: 'AI Summary',
            onTap: () => _withDocument(context, ref, 'Summarize…', (doc) async {
              if (context.mounted) context.push('/document/${doc.id}/ai');
            }),
          ),
          _Tool(
            icon: Icons.data_object_rounded,
            label: 'AI Extract',
            onTap: () =>
                _withDocument(context, ref, 'Extract from…', (doc) async {
                  if (context.mounted) context.push('/document/${doc.id}/ai');
                }),
          ),
        ]),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

/// Modal document picker used by document-scoped tools.
Future<ScanDocument?> pickDocument(
  BuildContext context,
  WidgetRef ref, {
  required String title,
}) async {
  final docs = ref.read(activeDocumentsProvider);
  if (docs.isEmpty) return null;
  return AppBottomSheet.show<ScanDocument>(
    context,
    title: title,
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
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          return DocumentRow(
            document: doc,
            onShell: false,
            onLongPress: () {},
            onTap: () => Navigator.of(context).pop(doc),
          );
        },
      ),
    ),
  );
}

class _Tool {
  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});

  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final width =
        (context.screenSize.width - AppSpacing.lg * 2 - AppSpacing.md * 3) / 4;
    return PressableTap(
      onTap: tool.onTap,
      child: Container(
        width: width.clamp(72, 110),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.toolCard,
          borderRadius: AppShapes.cardRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  tool.icon,
                  color: colors.textPrimary,
                  size: 24,
                  semanticLabel: tool.label,
                ),
                if (tool.badge != null)
                  Positioned(
                    top: -8,
                    right: -18,
                    child: Text(
                      tool.badge!,
                      style: AppTypography.mono(colors.accent, size: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(tool.label, style: AppTypography.caption(colors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
