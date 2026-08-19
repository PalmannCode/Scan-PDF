import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/errors/user_message.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/auth/presentation/providers/auth_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_saver_provider.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/services/ai_service.dart';
import 'package:scanpdf/services/cloud_sync_provider.dart';
import 'package:scanpdf/services/workflow_service.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

class WorkflowsScreen extends ConsumerStatefulWidget {
  const WorkflowsScreen({super.key});

  @override
  ConsumerState<WorkflowsScreen> createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends ConsumerState<WorkflowsScreen> {
  String? _running;

  Future<ScanDocument?> _pickDocument() async {
    final docs = ref.read(activeDocumentsProvider);
    if (docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create or import a document first.')),
        );
      }
      return null;
    }
    return showDialog<ScanDocument>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose a document'),
        children: [
          for (final document in docs)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(document),
              child: Text('${document.title} · ${document.pageCount} pages'),
            ),
        ],
      ),
    );
  }

  Future<void> _run(DocumentWorkflow workflow) async {
    final doc = await _pickDocument();
    if (doc == null || !mounted) return;
    setState(() => _running = workflow.id);
    try {
      switch (workflow.id) {
        case 'scan_ocr_upload':
          if (ref.read(authUserProvider).value == null) {
            context.push('/account');
            return;
          }
          await ref.read(scanSaverProvider).runOcr(doc.id);
          final updated = ref.read(documentRepositoryProvider).getById(doc.id);
          if (updated != null) {
            await ref.read(cloudSyncServiceProvider).uploadDocument(updated);
          }
        case 'scan_sign_email':
          context.push('/document/${doc.id}/sign');
        case 'image_convert_pdf':
          await ref.read(exportServiceProvider).sharePdf(doc);
        case 'receipt_expense':
          await ref.read(scanSaverProvider).runOcr(doc.id);
          if (mounted) {
            context.push(
              '/document/${doc.id}/ai?action=${AiAction.extract.name}',
            );
          }
      }
      await ref
          .read(analyticsServiceProvider)
          .track(
            'workflow_completed',
            properties: {
              'tool_name': workflow.id,
              'document_id': doc.id,
              'screen_name': 'workflows',
            },
          );
      if (mounted &&
          workflow.id != 'scan_sign_email' &&
          workflow.id != 'receipt_expense') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${workflow.name} completed.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userMessageFor(
                error,
                fallback: 'The workflow could not be completed. Try again.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plus = ref.watch(plusProvider.select((state) => state.isActive));
    final store = ref.watch(workflowStoreProvider);
    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          onTap: () => context.pop(),
          child: Icon(Icons.close_rounded, color: colors.textPrimary),
        ),
        title: Text(
          'Workflows',
          style: AppTypography.title(colors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: !plus
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.route_rounded, size: 64, color: colors.accent),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Workflows are included with Plus',
                      textAlign: TextAlign.center,
                      style: AppTypography.headline(colors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Combine repeatable document steps into one guided action.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: () => context.push('/paywall'),
                      child: const Text('View Plus'),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Repeatable document actions',
                    style: AppTypography.headline(colors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Enable the workflows you use. They are stored locally and their configuration syncs when you sign in.',
                    style: AppTypography.body(colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final workflow in DocumentWorkflow.templates)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colors.paperCard,
                        borderRadius: AppShapes.cardRadius,
                        border: Border.all(color: colors.hairline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  workflow.name,
                                  style: AppTypography.title(
                                    colors.textPrimary,
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: store.isEnabled(workflow.id),
                                onChanged: (enabled) async {
                                  try {
                                    await store.setEnabled(workflow, enabled);
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            userMessageFor(
                                              error,
                                              fallback:
                                                  'The workflow setting could not be saved.',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                  if (mounted) setState(() {});
                                },
                              ),
                            ],
                          ),
                          Text(
                            workflow.description,
                            style: AppTypography.body(colors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              for (
                                var i = 0;
                                i < workflow.steps.length;
                                i++
                              ) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.toolCard,
                                    borderRadius: AppShapes.pillRadius,
                                  ),
                                  child: Text(
                                    workflow.steps[i],
                                    style: AppTypography.caption(
                                      colors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (i < workflow.steps.length - 1)
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: colors.textSecondary,
                                  ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed:
                                  store.isEnabled(workflow.id) &&
                                      _running == null
                                  ? () => _run(workflow)
                                  : null,
                              icon: _running == workflow.id
                                  ? SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.accent,
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow_rounded),
                              label: const Text('Run'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
