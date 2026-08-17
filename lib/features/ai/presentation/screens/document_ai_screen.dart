import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/errors/user_message.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/auth/presentation/providers/auth_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_saver_provider.dart';
import 'package:scanpdf/services/ai_provider.dart';
import 'package:scanpdf/services/ai_service.dart';

class DocumentAiScreen extends ConsumerStatefulWidget {
  const DocumentAiScreen({
    super.key,
    required this.documentId,
    this.initialAction = AiAction.ask,
  });

  final String documentId;
  final AiAction initialAction;

  @override
  ConsumerState<DocumentAiScreen> createState() => _DocumentAiScreenState();
}

class _DocumentAiScreenState extends ConsumerState<DocumentAiScreen> {
  final _question = TextEditingController();
  final _targetLanguage = TextEditingController(text: 'English');
  late AiAction _action;
  Map<String, dynamic>? _result;
  bool _working = false;
  bool _privacyAccepted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _action = widget.initialAction;
  }

  @override
  void dispose() {
    _question.dispose();
    _targetLanguage.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (ref.read(authUserProvider).value == null) {
      context.push('/account');
      return;
    }
    final initialDocument = ref.read(documentByIdProvider(widget.documentId));
    if (initialDocument == null) return;
    if (!initialDocument.hasOcr) {
      setState(() => _working = true);
      await ref.read(scanSaverProvider).runOcr(initialDocument.id);
      if (mounted) setState(() => _working = false);
    }
    final document = ref.read(documentByIdProvider(widget.documentId));
    if (document == null || !document.hasOcr) {
      if (mounted) {
        setState(() => _error = 'No readable text was found in this document.');
      }
      return;
    }
    if (!mounted) return;
    if (!_privacyAccepted) {
      final accepted = await AdaptiveDialog.confirm(
        context,
        title: 'Process this document with AI?',
        message:
            'The recognized text will be sent securely to the configured AI service. Page images stay local unless a vision tool explicitly asks for one.',
        cancelLabel: 'Cancel',
        confirmLabel: 'Continue',
      );
      if (!accepted) return;
      _privacyAccepted = true;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(aiServiceProvider)
          .run(
            action: _action,
            text: document.ocrText,
            question: _question.text.trim().isEmpty
                ? null
                : _question.text.trim(),
            targetLanguage: _action == AiAction.translate
                ? _targetLanguage.text.trim()
                : null,
          );
      if (mounted) setState(() => _result = response.result);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = userMessageFor(
            error,
            fallback:
                'The AI request could not be completed. Check your connection and try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final document = ref.watch(documentByIdProvider(widget.documentId));
    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          style: PressStyle.dim,
          onTap: () => context.pop(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
        ),
        title: Text(
          'Document AI',
          style: AppTypography.title(colors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              document?.title ?? 'Document',
              style: AppTypography.headline(colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final action in [
                  AiAction.ask,
                  AiAction.summary,
                  AiAction.extract,
                  AiAction.translate,
                ])
                  ChoiceChip(
                    label: Text(switch (action) {
                      AiAction.ask => 'Ask AI',
                      AiAction.summary => 'Summary',
                      AiAction.extract => 'Extract',
                      AiAction.translate => 'Translate',
                      AiAction.count => 'Count',
                    }),
                    selected: _action == action,
                    onSelected: (_) => setState(() {
                      _action = action;
                      _result = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_action == AiAction.ask)
              TextField(
                controller: _question,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'What are the key dates?',
                ),
              ),
            if (_action == AiAction.translate)
              TextField(
                controller: _targetLanguage,
                decoration: const InputDecoration(labelText: 'Target language'),
              ),
            if (_action == AiAction.summary)
              Text(
                'Creates a concise summary, key points, and action items.',
                style: AppTypography.body(colors.textSecondary),
              ),
            if (_action == AiAction.extract)
              Text(
                'Extracts document type, dates, names, totals, addresses, tasks, and line items as structured data.',
                style: AppTypography.body(colors.textSecondary),
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _working ? null : _run,
              icon: _working
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_working ? 'Processing…' : 'Run ${_action.name}'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(_error!, style: AppTypography.body(colors.danger)),
            ],
            if (_result != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.paperCard,
                  borderRadius: AppShapes.cardRadius,
                ),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(_result),
                  style: AppTypography.mono(colors.textPrimary, size: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
