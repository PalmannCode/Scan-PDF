import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/errors/user_message.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/auth/presentation/providers/auth_provider.dart';
import 'package:scanpdf/services/ai_provider.dart';
import 'package:scanpdf/services/ai_service.dart';

class ObjectCountScreen extends ConsumerStatefulWidget {
  const ObjectCountScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  ConsumerState<ObjectCountScreen> createState() => _ObjectCountScreenState();
}

class _ObjectCountScreenState extends ConsumerState<ObjectCountScreen> {
  final _object = TextEditingController();
  Map<String, dynamic>? _result;
  String? _error;
  bool _working = false;
  final _manualCount = TextEditingController();

  @override
  void dispose() {
    _object.dispose();
    _manualCount.dispose();
    super.dispose();
  }

  Future<void> _count() async {
    final user = await ref.read(authUserProvider.future);
    if (!mounted) return;
    if (user == null) {
      context.push('/account');
      return;
    }
    final consent = await AdaptiveDialog.confirm(
      context,
      title: 'Process this image with AI?',
      message:
          'This captured image will be sent to the configured AI service for object counting.',
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
            action: AiAction.count,
            imagePath: widget.imagePath,
            question: _object.text.trim().isEmpty
                ? null
                : 'Count ${_object.text.trim()}.',
          );
      if (mounted) {
        setState(() {
          _result = response.result;
          _manualCount.text = '${response.result['count'] ?? 0}';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = userMessageFor(
            error,
            fallback:
                'Object counting could not be completed. Check your connection and try again.',
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
          'Count Objects',
          style: AppTypography.title(colors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(widget.imagePath),
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _object,
              decoration: const InputDecoration(
                labelText: 'What should I count?',
                hintText: 'Optional, e.g. coins',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _working ? null : _count,
              icon: const Icon(Icons.calculate_outlined),
              label: Text(_working ? 'Counting…' : 'Count objects'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Text(_error!, style: TextStyle(color: colors.danger)),
              ),
            if (_result != null) ...[
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _manualCount,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: AppTypography.display(colors.accent),
                decoration: const InputDecoration(
                  labelText: 'Count — tap to correct',
                ),
              ),
              Text(
                '${_result!['object_label'] ?? 'objects'}',
                textAlign: TextAlign.center,
                style: AppTypography.title(colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(widget.imagePath)],
                    text:
                        'Counted ${_manualCount.text} ${_result!['object_label'] ?? 'objects'}. ${_result!['notes'] ?? ''}',
                  ),
                ),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Save or share result'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${_result!['notes'] ?? ''}',
                textAlign: TextAlign.center,
                style: AppTypography.body(colors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
