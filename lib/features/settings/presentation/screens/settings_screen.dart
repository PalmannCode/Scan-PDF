import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/constants/app_constants.dart';
import 'package:scanpdf/core/constants/url_constants.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/event/domain/event_phase.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/features/settings/presentation/widgets/settings_tile.dart';
import 'package:scanpdf/shared/models/enums.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(settingsProvider);
    final plusActive =
        ref.watch(plusProvider.select((s) => s.isActive));
    final eventPhase = currentEventPhase();

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          style: PressStyle.dim,
          onTap: () => context.pop(),
          child: Icon(Icons.close_rounded,
              color: colors.textPrimary, semanticLabel: 'Close'),
        ),
        title: Text('Settings',
            style: AppTypography.title(colors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (!plusActive) const _PlusBanner(),
            if (plusActive) const _PlusActiveCard(),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'GENERAL',
              children: [
                SettingsTile(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Recommend App',
                  onTap: () => SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Scan documents into clean PDFs with ${AppConstants.appNameShort}: ${AppConstants.appStoreUrl}',
                    ),
                  ),
                ),
                if (eventPhase != EventPhase.ended)
                  SettingsTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Receipt Rescue Challenge',
                    value: eventPhase == EventPhase.upcoming
                        ? 'Starts ${DateFormat.MMMd().format(AppConstants.eventStart)}'
                        : 'Live now',
                    onTap: () => context.push('/event'),
                  ),
              ],
            ),
            SettingsSection(
              title: 'SCANNING',
              children: [
                SettingsTile(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Default filter',
                  value: settings.defaultFilter.label,
                  onTap: () => _cycleFilter(ref, settings.defaultFilter),
                ),
                SettingsToggleTile(
                  icon: Icons.text_fields_rounded,
                  label: 'Recognize text after scan',
                  value: settings.autoOcrAfterScan,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .update((s) => s.copyWith(autoOcrAfterScan: v)),
                ),
                SettingsTile(
                  icon: Icons.high_quality_outlined,
                  label: 'Image quality',
                  value: switch (settings.imageQuality) {
                    <= 70 => 'Compact',
                    >= 95 => 'Maximum',
                    _ => 'Balanced',
                  },
                  onTap: () => _cycleQuality(ref, settings.imageQuality),
                ),
              ],
            ),
            SettingsSection(
              title: 'APPEARANCE',
              children: [
                SettingsTile(
                  icon: Icons.brightness_6_outlined,
                  label: 'Theme',
                  value: switch (settings.themeMode) {
                    'light' => 'Light',
                    'dark' => 'Dark',
                    _ => 'System',
                  },
                  onTap: () => _cycleTheme(ref, settings.themeMode),
                ),
              ],
            ),
            SettingsSection(
              title: 'SUPPORT',
              children: [
                SettingsTile(
                  icon: Icons.support_agent_rounded,
                  label: plusActive ? 'Priority Support' : 'Contact Us',
                  onTap: () => _open(UrlConstants.support),
                ),
                SettingsTile(
                  icon: Icons.star_outline_rounded,
                  label: 'Rate App',
                  onTap: () => _open(
                      '${AppConstants.appStoreUrl}?action=write-review'),
                ),
              ],
            ),
            SettingsSection(
              title: 'LEGAL',
              children: [
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => _open(UrlConstants.privacyPolicy),
                ),
                SettingsTile(
                  icon: Icons.description_outlined,
                  label: 'Terms of Use',
                  onTap: () => _open(UrlConstants.termsOfService),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                '${AppConstants.appNameShort} 1.0.0',
                style: AppTypography.mono(colors.textSecondary, size: 11),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _cycleFilter(WidgetRef ref, ScanFilter current) {
    const values = ScanFilter.values;
    final next = values[(values.indexOf(current) + 1) % values.length];
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(defaultFilter: next));
  }

  void _cycleQuality(WidgetRef ref, int current) {
    final next = switch (current) {
      <= 70 => 85,
      >= 95 => 70,
      _ => 95,
    };
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(imageQuality: next));
  }

  void _cycleTheme(WidgetRef ref, String current) {
    final next = switch (current) {
      'system' => 'light',
      'light' => 'dark',
      _ => 'system',
    };
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(themeMode: next));
  }
}

class _PlusBanner extends ConsumerWidget {
  const _PlusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return PressableTap(
      onTap: () => context.push('/paywall'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.accent, colors.accentDeep],
          ),
          borderRadius: AppShapes.cardRadius,
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 28,
                semanticLabel: 'Plus'),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upgrade to Plus',
                      style: AppTypography.title(Colors.white)),
                  Text(
                    'Reusable signatures & priority support',
                    style: AppTypography.caption(
                        Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, semanticLabel: 'Open paywall'),
          ],
        ),
      ),
    );
  }
}

class _PlusActiveCard extends StatelessWidget {
  const _PlusActiveCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: AppShapes.cardRadius,
        border: Border.all(color: colors.success, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded,
              color: colors.success,
              size: 24,
              semanticLabel: 'Plus active'),
          const SizedBox(width: AppSpacing.md),
          Text('Plus is active',
              style: AppTypography.bodyMedium(colors.textPrimary)),
        ],
      ),
    );
  }
}
