import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/constants/app_constants.dart';
import 'package:scanpdf/core/constants/url_constants.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/app_background.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/services/purchase_service.dart';
import 'package:scanpdf/services/analytics_service.dart';

/// Plus paywall (Jira §7): direct App Store subscription, soft gate.
/// Core local scanning remains usable without it; advanced cloud, AI,
/// conversion, automation, and support tools are gated.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(analyticsServiceProvider)
          .track('paywall_viewed', properties: {'screen_name': 'paywall'}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plus = ref.watch(plusProvider);

    return Scaffold(
      backgroundColor: colors.shellBg,
      body: AppBackground(
        treatment: BackgroundTreatment.shell,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: PressableTap(
                    style: PressStyle.dim,
                    onTap: () => context.pop(),
                    child: Icon(
                      Icons.close_rounded,
                      color: colors.onShell,
                      semanticLabel: 'Close paywall',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: plus.isActive
                      ? const _PlusActiveBody()
                      : _PlusOfferBody(plus: plus),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusActiveBody extends StatelessWidget {
  const _PlusActiveBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.huge),
        Icon(
          Icons.verified_rounded,
          color: colors.success,
          size: 56,
          semanticLabel: 'Active',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Plus is active', style: AppTypography.display(colors.onShell)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'AI, cloud backup, advanced conversion, workflows, reusable signatures, expense reports, and priority support are unlocked.',
          textAlign: TextAlign.center,
          style: AppTypography.body(colors.onShellMuted),
        ),
      ],
    );
  }
}

class _PlusOfferBody extends ConsumerWidget {
  const _PlusOfferBody({required this.plus});

  final PlusState plus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final canBuy = plus.storeAvailable && plus.product != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Scan PDF ', style: AppTypography.display(colors.onShell)),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.accent, colors.accentDeep],
                ),
                borderRadius: AppShapes.thumbnailRadius,
              ),
              child: Text('PLUS', style: AppTypography.headline(Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const _Benefit(
          icon: Icons.auto_awesome_rounded,
          title: 'Advanced document tools',
          subtitle:
              'Word and PowerPoint, Book Scan, translation, compression, watermarks, and workflows.',
        ),
        const _Benefit(
          icon: Icons.cloud_upload_outlined,
          title: 'Cloud productivity',
          subtitle:
              'Auto Upload, reusable signatures, expense reports, and priority support.',
        ),
        const _Benefit(
          icon: Icons.psychology_outlined,
          title: 'More AI and OCR',
          subtitle:
              'Expanded document Q&A, extraction, translation, and recognition limits.',
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.shellElevated,
            borderRadius: AppShapes.cardRadius,
          ),
          child: Column(
            children: [
              Text(
                AppConstants.plusTrialText,
                style: AppTypography.title(colors.onShell),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'then ${plus.priceLabel} per ${AppConstants.plusBillingPeriod}',
                style: AppTypography.mono(colors.onShellMuted, size: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PressableTap(
          onTap: canBuy && !plus.purchasing
              ? () => ref.read(plusProvider.notifier).buy()
              : null,
          enabled: canBuy && !plus.purchasing,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: canBuy
                  ? colors.accent
                  : colors.accent.withValues(alpha: 0.35),
              borderRadius: AppShapes.buttonRadius,
            ),
            child: Text(
              plus.purchasing
                  ? 'Processing…'
                  : canBuy
                  ? 'Start free trial'
                  : 'Store unavailable',
              textAlign: TextAlign.center,
              style: AppTypography.title(Colors.white),
            ),
          ),
        ),
        if (plus.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            plus.error!,
            textAlign: TextAlign.center,
            style: AppTypography.caption(colors.danger),
          ),
        ],
        if (!canBuy && !plus.purchasing) ...[
          const SizedBox(height: AppSpacing.sm),
          PressableTap(
            style: PressStyle.dim,
            onTap: () => ref.read(plusProvider.notifier).reloadProduct(),
            child: Text(
              'Check the App Store again',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(colors.onShell),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PressableTap(
          style: PressStyle.dim,
          onTap: () => ref.read(plusProvider.notifier).restore(),
          child: Text(
            'Restore Purchases',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(colors.onShell),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Auto-renewable monthly subscription. Payment is charged to your '
          'Apple ID at confirmation. Renews automatically unless cancelled '
          'at least 24 hours before the end of the period. Manage or cancel '
          'any time in App Store settings. Core local scanning and PDF '
          'sharing remain available without Plus.',
          textAlign: TextAlign.center,
          style: AppTypography.caption(
            colors.onShellMuted.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _LegalLinks(),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.16),
              borderRadius: AppShapes.thumbnailRadius,
            ),
            child: Icon(
              icon,
              color: colors.accent,
              size: 22,
              semanticLabel: title,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium(colors.onShell)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption(colors.onShellMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = AppTypography.caption(colors.onShellMuted).copyWith(
      decoration: TextDecoration.underline,
      decorationColor: colors.onShellMuted,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Privacy Policy',
            style: style,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(
                Uri.parse(UrlConstants.privacyPolicy),
                mode: LaunchMode.inAppBrowserView,
              ),
          ),
          TextSpan(
            text: '   ·   ',
            style: AppTypography.caption(colors.onShellMuted),
          ),
          TextSpan(
            text: 'Terms of Use',
            style: style,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(
                Uri.parse(UrlConstants.termsOfService),
                mode: LaunchMode.inAppBrowserView,
              ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
