import 'dart:async';
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
  bool _limitReached = false;
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
    // Every early exit below must leave a visible trace. Previously several of
    // them returned in silence, so the button looked dead even though the
    // handler had run.
    setState(() {
      _working = true;
      _error = null;
      _limitReached = false;
    });

    // Await the first auth emission: a synchronous read of the stream provider
    // is still AsyncLoading on the first tap, so a signed-in user would be
    // bounced to /account instead of running the tool.
    // Bounded: fall back to the synchronous session rather than spinning
    // forever if the auth stream is slow to produce its first value.
    final user = await ref
        .read(authUserProvider.future)
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => ref.read(authServiceProvider).currentUser,
        );
    if (!mounted) return;
    if (user == null) {
      setState(() {
        _working = false;
        _error = 'Sign in to use AI tools. Opening your account…';
      });
      context.push('/account');
      return;
    }
    final initialDocument = ref.read(documentByIdProvider(widget.documentId));
    if (initialDocument == null) {
      setState(() {
        _working = false;
        _error = 'This document is no longer available.';
      });
      return;
    }
    if (!initialDocument.hasOcr) {
      // Recognition can take many seconds; the button already reads
      // "Processing…" so the wait is attributable.
      await ref.read(scanSaverProvider).runOcr(initialDocument.id);
      if (!mounted) return;
    }
    final document = ref.read(documentByIdProvider(widget.documentId));
    if (document == null || !document.hasOcr) {
      setState(() {
        _working = false;
        _error = 'No readable text was found in this document.';
      });
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
      if (!accepted) {
        if (mounted) setState(() => _working = false);
        return;
      }
      _privacyAccepted = true;
    }
    if (!mounted) return;
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
        setState(() {
          _limitReached = error is AiLimitReachedError;
          _error = userMessageFor(
            error,
            fallback:
                'The AI request could not be completed. Check your connection and try again.',
          );
        });
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
                  ? SizedBox.square(
                      dimension: 18,
                      // Without a colour this falls back to colorScheme.primary
                      // (deep indigo), which is 2.7:1 on the button fill in the
                      // dark theme — the busy state disappears.
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.textPrimary,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_working ? 'Processing…' : 'Run ${_action.name}'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(_error!, style: AppTypography.body(colors.danger)),
              if (_limitReached) ...[
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: () => context.push('/paywall'),
                  child: const Text('Upgrade to Plus'),
                ),
              ],
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
