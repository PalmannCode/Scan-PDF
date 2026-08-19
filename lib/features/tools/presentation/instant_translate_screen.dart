import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/errors/user_message.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/auth/presentation/providers/auth_provider.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/services/ai_provider.dart';
import 'package:scanpdf/services/ai_service.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

class InstantTranslateScreen extends ConsumerStatefulWidget {
  const InstantTranslateScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  ConsumerState<InstantTranslateScreen> createState() =>
      _InstantTranslateScreenState();
}

class _InstantTranslateScreenState
    extends ConsumerState<InstantTranslateScreen> {
  final _target = TextEditingController(text: 'English');
  String? _ocr;
  Map<String, dynamic>? _result;
  String? _error;
  bool _working = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_recognize);
  }

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _recognize() async {
    try {
      final languages = switch (ref.read(settingsProvider).ocrLanguageBundle) {
        'western' => const ['en-US', 'fr-FR', 'de-DE', 'es-ES', 'it-IT'],
        'cjk' => const ['zh-Hans', 'ja-JP', 'ko-KR', 'en-US'],
        _ => const ['en-US'],
      };
      final text = await ref
          .read(ocrServiceProvider)
          .recognizeFile(widget.imagePath, languages: languages);
      if (mounted) {
        setState(() {
          _ocr = text;
          _working = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Text recognition failed: $error';
          _working = false;
        });
      }
    }
  }

  Future<void> _translate() async {
    if ((_ocr ?? '').trim().isEmpty) {
      setState(() => _error = 'No readable text was found.');
      return;
    }
    final user = await ref.read(authUserProvider.future);
    if (!mounted) return;
    if (user == null) {
      context.push('/account');
      return;
    }
    final consent = await AdaptiveDialog.confirm(
      context,
      title: 'Send recognized text for translation?',
      message:
          'Only the recognized text will be sent to the configured AI service; the image stays on this device.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Continue',
    );
    if (!consent) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(aiServiceProvider)
          .run(
            action: AiAction.translate,
            text: _ocr,
            targetLanguage: _target.text.trim(),
          );
      if (mounted) setState(() => _result = response.result);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = userMessageFor(
            error,
            fallback:
                'Translation could not be completed. Check your connection and try again.',
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
    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          onTap: () => context.go('/'),
          child: Icon(Icons.close_rounded, color: colors.textPrimary),
        ),
        title: Text(
          'Translate',
          style: AppTypography.title(colors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ClipRRect(
              borderRadius: AppShapes.cardRadius,
              child: Image.file(
                File(widget.imagePath),
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _target,
              decoration: const InputDecoration(labelText: 'Target language'),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _working ? null : _translate,
              icon: const Icon(Icons.translate_rounded),
              label: Text(_working ? 'Recognizing…' : 'Translate text'),
            ),
            if (_ocr != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Recognized text',
                style: AppTypography.label(colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                _ocr!,
                style: AppTypography.body(colors.textPrimary),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Translation',
                style: AppTypography.label(colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.paperCard,
                  borderRadius: AppShapes.cardRadius,
                ),
                child: SelectableText(
                  '${_result!['translation'] ?? _result!['answer'] ?? ''}',
                  style: AppTypography.body(colors.textPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final translated =
                            '${_result!['translation'] ?? _result!['answer'] ?? ''}';
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(
                          ClipboardData(text: translated),
                        );
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Copied')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final translated =
                            '${_result!['translation'] ?? _result!['answer'] ?? ''}';
                        SharePlus.instance.share(ShareParams(text: translated));
                      },
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Save / Share'),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Text(_error!, style: TextStyle(color: colors.danger)),
              ),
          ],
        ),
      ),
    );
  }
}
