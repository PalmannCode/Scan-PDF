import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/constants/url_constants.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/errors/user_message.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/auth/presentation/providers/auth_provider.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/services/support_service.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().length < 10) {
      setState(() => _error = 'Add a subject and at least 10 characters.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(supportServiceProvider)
          .createPriorityTicket(subject: _subject.text, message: _message.text);
      await ref
          .read(analyticsServiceProvider)
          .track(
            'priority_support_ticket_created',
            properties: {'screen_name': 'priority_support'},
          );
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = userMessageFor(
            error,
            fallback:
                'The support request could not be sent. Check your connection and try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plus = ref.watch(plusProvider.select((state) => state.isActive));
    final user = ref.watch(authUserProvider).value;
    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          onTap: () => context.pop(),
          child: Icon(Icons.close_rounded, color: colors.textPrimary),
        ),
        title: Text('Support', style: AppTypography.title(colors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (!plus) ...[
              Icon(Icons.support_agent_rounded, size: 56, color: colors.accent),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Contact Support',
                style: AppTypography.headline(colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Use the support form for general questions, feedback, or bug reports. Plus members can create priority tickets directly in the app.',
                style: AppTypography.body(colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(UrlConstants.support),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Support Form'),
              ),
              TextButton(
                onPressed: () => context.push('/paywall'),
                child: const Text('Upgrade for Priority Support'),
              ),
            ] else if (user == null) ...[
              Text(
                'Priority Support',
                style: AppTypography.headline(colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in so your ticket can be linked to your Plus account and followed through to resolution.',
                style: AppTypography.body(colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.push('/account'),
                child: const Text('Sign In'),
              ),
            ] else if (_sent) ...[
              Icon(Icons.check_circle_rounded, size: 64, color: colors.success),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Ticket sent',
                textAlign: TextAlign.center,
                style: AppTypography.headline(colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your priority request is securely attached to your account.',
                textAlign: TextAlign.center,
                style: AppTypography.body(colors.textSecondary),
              ),
            ] else ...[
              Text(
                'Priority Support',
                style: AppTypography.headline(colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tell us what happened and include the steps needed to reproduce it. Do not include passwords or private document text.',
                style: AppTypography.body(colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _subject,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _message,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.danger.withValues(alpha: 0.08),
                    borderRadius: AppShapes.buttonRadius,
                  ),
                  child: Text(
                    _error!,
                    style: AppTypography.caption(colors.danger),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _sending ? null : _submit,
                child: Text(_sending ? 'Sending…' : 'Send Priority Ticket'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
