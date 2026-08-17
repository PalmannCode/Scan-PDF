import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';

class EmailTemplateScreen extends ConsumerStatefulWidget {
  const EmailTemplateScreen({super.key});

  @override
  ConsumerState<EmailTemplateScreen> createState() =>
      _EmailTemplateScreenState();
}

class _EmailTemplateScreenState extends ConsumerState<EmailTemplateScreen> {
  late final TextEditingController _subject;
  late final TextEditingController _body;
  late final TextEditingController _signature;
  late String _format;
  late bool _includeDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _subject = TextEditingController(text: settings.defaultEmailSubject);
    _body = TextEditingController(text: settings.defaultEmailBody);
    _signature = TextEditingController(text: settings.defaultEmailSignature);
    _format = settings.emailAttachmentFormat;
    _includeDate = settings.includeDocumentDate;
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    _signature.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(settingsProvider.notifier)
        .update(
          (settings) => settings.copyWith(
            defaultEmailSubject: _subject.text.trim(),
            defaultEmailBody: _body.text.trim(),
            defaultEmailSignature: _signature.text.trim(),
            emailAttachmentFormat: _format,
            includeDocumentDate: _includeDate,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          onTap: () => context.pop(),
          child: Icon(Icons.close_rounded, color: colors.textPrimary),
        ),
        title: Text(
          'Email Template',
          style: AppTypography.title(colors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Use {title} and {date} as placeholders. The template is applied to document share sheets that support a subject and message.',
              style: AppTypography.body(colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _subject,
              decoration: const InputDecoration(labelText: 'Default subject'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _body,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Default body'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _signature,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Email signature'),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _format,
              decoration: const InputDecoration(labelText: 'Attachment format'),
              items: const [
                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                DropdownMenuItem(value: 'jpg', child: Text('JPG images')),
                DropdownMenuItem(value: 'png', child: Text('PNG images')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _format = value);
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include document date'),
              value: _includeDate,
              onChanged: (value) => setState(() => _includeDate = value),
            ),
          ],
        ),
      ),
    );
  }
}
