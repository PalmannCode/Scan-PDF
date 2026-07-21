import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/constants/url_constants.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/core/widgets/app_background.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/onboarding/domain/models/onboarding_step.dart';
import 'package:scanpdf/features/onboarding/presentation/widgets/onboarding_scenes.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(appStateRepositoryProvider).completeOnboarding();
    if (!mounted) return;
    context.go('/');
  }

  void _next() {
    if (_page >= onboardingSteps.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppMotion.sheet,
      curve: AppMotion.enter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLast = _page == onboardingSteps.length - 1;
    return Scaffold(
      backgroundColor: colors.shellBg,
      body: AppBackground(
        treatment: BackgroundTreatment.shell,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: PressableTap(
                    style: PressStyle.dim,
                    onTap: _finish,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Text(
                        'Skip',
                        style: AppTypography.bodyMedium(colors.onShellMuted),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingSteps.length,
                  onPageChanged: (index) {
                    Haptics.selection();
                    setState(() => _page = index);
                  },
                  itemBuilder: (context, index) =>
                      _OnboardingPage(step: onboardingSteps[index], index: index),
                ),
              ),
              _TickDashIndicator(current: _page),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl),
                child: PressableTap(
                  onTap: _next,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: AppShapes.buttonRadius,
                    ),
                    child: Text(
                      isLast ? 'Start scanning' : 'Continue',
                      textAlign: TextAlign.center,
                      style: AppTypography.title(Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _ConsentFooter(),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.step, required this.index});

  final OnboardingStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scene = switch (index) {
      0 => const ScanSceneIllustration(),
      1 => const EditSceneIllustration(),
      _ => const ExportSceneIllustration(),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          scene,
          const SizedBox(height: AppSpacing.xxl),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: AppTypography.display(colors.onShell),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            step.subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.body(colors.onShellMuted),
          ),
        ],
      ),
    );
  }
}

/// Swiss tick-dash progress (not dots): short mono dashes, active = accent.
class _TickDashIndicator extends StatelessWidget {
  const _TickDashIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < onboardingSteps.length; i++)
          AnimatedContainer(
            duration: AppMotion.standard,
            curve: AppMotion.enter,
            margin:
                const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width: i == current ? 28 : 14,
            height: 3,
            decoration: BoxDecoration(
              color: i == current
                  ? colors.accent
                  : colors.onShell.withValues(alpha: 0.25),
              borderRadius: AppShapes.pillRadius,
            ),
          ),
      ],
    );
  }
}

class _ConsentFooter extends StatelessWidget {
  const _ConsentFooter();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = AppTypography.caption(
        colors.onShellMuted.withValues(alpha: 0.8));
    final link = base.copyWith(
      color: colors.onShell,
      decoration: TextDecoration.underline,
      decorationColor: colors.onShellMuted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Text.rich(
        TextSpan(
          text: 'By continuing, you agree to our ',
          style: base,
          children: [
            TextSpan(
              text: 'Privacy Policy',
              style: link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrl(
                      Uri.parse(UrlConstants.privacyPolicy),
                      mode: LaunchMode.inAppBrowserView,
                    ),
            ),
            TextSpan(text: ' and ', style: base),
            TextSpan(
              text: 'Terms of Service',
              style: link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrl(
                      Uri.parse(UrlConstants.termsOfService),
                      mode: LaunchMode.inAppBrowserView,
                    ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
