import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/config/app_config.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/errors/user_message.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/auth/presentation/providers/auth_provider.dart';
import 'package:scanpdf/services/analytics_service.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _email = TextEditingController();
  bool _working = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(analyticsServiceProvider)
          .track('auth_screen_opened', properties: {'screen_name': 'account'}),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = userMessageFor(
            error,
            fallback:
                'The account request could not be completed. Check your connection and try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _sendLink() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _message = 'Enter a valid email address.');
      return;
    }
    await _run(() => ref.read(authServiceProvider).sendEmailLink(email));
    if (mounted && _message == null) {
      setState(
        () => _message = 'Check your email for the secure sign-in link.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final auth = ref.watch(authUserProvider);
    final user = auth.value;
    final configured = AppConfig.hasSupabase;

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          style: PressStyle.dim,
          // The magic-link deep link lands here with an empty stack, so
          // back must fall through to home instead of throwing on pop.
          onTap: () => context.canPop() ? context.pop() : context.go('/'),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
            semanticLabel: 'Back',
          ),
        ),
        title: Text('Account', style: AppTypography.title(colors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.paperCard,
                borderRadius: AppShapes.cardRadius,
              ),
              child: user == null
                  ? _GuestAccount(
                      configured: configured,
                      email: _email,
                      working: _working,
                      onApple: () =>
                          _run(ref.read(authServiceProvider).signInWithApple),
                      onEmail: _sendLink,
                    )
                  : _SignedInAccount(
                      email: user.email ?? 'Apple account',
                      working: _working,
                      onSignOut: () =>
                          _run(ref.read(authServiceProvider).signOut),
                      onDelete: () async {
                        final confirmed = await AdaptiveDialog.confirm(
                          context,
                          title: 'Delete cloud account?',
                          message:
                              'Cloud metadata and uploaded files will be permanently deleted. Local scans stay on this device.',
                          confirmLabel: 'Delete account',
                          destructive: true,
                        );
                        if (confirmed) {
                          await _run(
                            ref.read(authServiceProvider).deleteAccount,
                          );
                        }
                      },
                    ),
            ),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: AppTypography.body(colors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Guest mode remains fully local. Sign in only if you want cloud backup, cross-device restore, AI tools, or synced Plus status.',
              style: AppTypography.body(colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestAccount extends StatelessWidget {
  const _GuestAccount({
    required this.configured,
    required this.email,
    required this.working,
    required this.onApple,
    required this.onEmail,
  });

  final bool configured;
  final TextEditingController email;
  final bool working;
  final VoidCallback onApple;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (!configured) {
      return Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: colors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cloud setup required',
            style: AppTypography.title(colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This build has no Supabase public configuration. Local scanning remains available.',
            textAlign: TextAlign.center,
            style: AppTypography.body(colors.textSecondary),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sign in', style: AppTypography.headline(colors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Keep local control and add private account-backed sync when you choose.',
          style: AppTypography.body(colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        IgnorePointer(
          ignoring: working,
          child: SignInWithAppleButton(
            onPressed: onApple,
            height: 50,
            // The button defaults to solid black, which vanishes against the
            // dark-theme card (#211D48) — Apple's guidelines ask for the white
            // variant on dark surfaces.
            style: context.isDark
                ? SignInWithAppleButtonStyle.white
                : SignInWithAppleButtonStyle.black,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => onEmail(),
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: working ? null : onEmail,
          child: Text(working ? 'Please wait…' : 'Email me a sign-in link'),
        ),
      ],
    );
  }
}

class _SignedInAccount extends StatelessWidget {
  const _SignedInAccount({
    required this.email,
    required this.working,
    required this.onSignOut,
    required this.onDelete,
  });

  final String email;
  final bool working;
  final VoidCallback onSignOut;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.verified_user_rounded, size: 44, color: colors.success),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Signed in',
          textAlign: TextAlign.center,
          style: AppTypography.title(colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          email,
          textAlign: TextAlign.center,
          style: AppTypography.body(colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton(
          onPressed: working ? null : onSignOut,
          child: const Text('Sign out'),
        ),
        TextButton(
          onPressed: working ? null : onDelete,
          child: Text('Delete account', style: TextStyle(color: colors.danger)),
        ),
      ],
    );
  }
}
