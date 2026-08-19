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
import 'package:scanpdf/core/errors/user_message.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/event/domain/event_phase.dart';
import 'package:scanpdf/features/auth/presentation/providers/auth_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/folders_provider.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/features/settings/presentation/widgets/settings_tile.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/services/cloud_sync_provider.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/features/viewer/presentation/providers/viewer_actions_provider.dart';
import 'package:scanpdf/core/utils/file_name_formats.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(settingsProvider);
    final plusActive = ref.watch(plusProvider.select((s) => s.isActive));
    final user = ref.watch(authUserProvider).value;
    final eventPhase = currentEventPhase();

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          style: PressStyle.dim,
          onTap: () => context.pop(),
          child: Icon(
            Icons.close_rounded,
            color: colors.textPrimary,
            semanticLabel: 'Close',
          ),
        ),
        title: Text('Settings', style: AppTypography.title(colors.textPrimary)),
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
                  icon: Icons.photo_camera_outlined,
                  label: 'Default camera mode',
                  value: settings.defaultCameraMode.label,
                  onTap: () =>
                      _cycleCameraMode(ref, settings.defaultCameraMode),
                ),
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
                  icon: Icons.language_rounded,
                  label: 'OCR language bundle',
                  value: switch (settings.ocrLanguageBundle) {
                    'western' => 'Western European',
                    'cjk' => 'Chinese, Japanese & Korean',
                    _ => 'Latin',
                  },
                  onTap: () => _cycleOcrBundle(ref, settings.ocrLanguageBundle),
                ),
                SettingsToggleTile(
                  icon: Icons.find_in_page_outlined,
                  label: 'Create searchable PDFs',
                  value: settings.createSearchablePdf,
                  onChanged: (enabled) => ref
                      .read(settingsProvider.notifier)
                      .update(
                        (current) =>
                            current.copyWith(createSearchablePdf: enabled),
                      ),
                ),
                SettingsToggleTile(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Auto Capture',
                  value: settings.autoCaptureEnabled,
                  onChanged: (enabled) async {
                    await ref
                        .read(settingsProvider.notifier)
                        .update(
                          (current) =>
                              current.copyWith(autoCaptureEnabled: enabled),
                        );
                    await ref
                        .read(analyticsServiceProvider)
                        .track(
                          'auto_capture_toggled',
                          properties: {'enabled': enabled},
                        );
                  },
                ),
                SettingsTile(
                  icon: Icons.high_quality_outlined,
                  label: 'Image quality',
                  value: switch (settings.imageQuality) {
                    <= 70 => 'Compact',
                    >= 95 => 'Maximum',
                    _ => 'Balanced',
                  },
                  onTap: () {
                    // Owner decision 2026-08-19: Maximum quality is the Plus
                    // hook, so a free user tapping this always sees the
                    // upsell rather than cycling between free values.
                    if (!plusActive) {
                      context.push('/paywall');
                      return;
                    }
                    _cycleQuality(ref, settings.imageQuality);
                  },
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
                SettingsTile(
                  icon: Icons.app_shortcut_rounded,
                  label: 'App Icon',
                  value: settings.appIcon == 'default'
                      ? 'Default'
                      : settings.appIcon,
                  onTap: () => context.push('/settings/app-icon'),
                ),
              ],
            ),
            SettingsSection(
              title: 'DOCUMENT TOOLS',
              children: [
                SettingsTile(
                  icon: Icons.draw_outlined,
                  label: 'Signatures',
                  value: plusActive ? 'Manage' : 'Plus',
                  onTap: () => context.push('/settings/signatures'),
                ),
                SettingsTile(
                  icon: Icons.route_rounded,
                  label: 'Workflows',
                  value: plusActive ? 'Configure' : 'Plus',
                  onTap: () => context.push('/settings/workflows'),
                ),
                SettingsTile(
                  icon: Icons.email_outlined,
                  label: 'Email Template',
                  value: settings.emailAttachmentFormat.toUpperCase(),
                  onTap: () => context.push('/settings/email-template'),
                ),
              ],
            ),
            SettingsSection(
              title: 'ADVANCED',
              children: [
                SettingsTile(
                  icon: Icons.drive_file_rename_outline_rounded,
                  label: 'Default file name',
                  value: switch (FileNameFormats.normalize(
                    settings.defaultFileNameFormat,
                  )) {
                    FileNameFormats.document => 'Document + date',
                    FileNameFormats.receipt => 'Receipt + date',
                    _ => 'Scan + date and time',
                  },
                  onTap: () =>
                      _cycleFileName(ref, settings.defaultFileNameFormat),
                ),
                SettingsToggleTile(
                  icon: Icons.bug_report_outlined,
                  label: 'Diagnostic logs',
                  value: settings.diagnosticLogsEnabled,
                  onChanged: (enabled) => ref
                      .read(settingsProvider.notifier)
                      .update(
                        (current) =>
                            current.copyWith(diagnosticLogsEnabled: enabled),
                      ),
                ),
              ],
            ),
            SettingsSection(
              title: 'SUBSCRIPTION',
              children: [
                SettingsTile(
                  icon: Icons.restore_rounded,
                  label: 'Restore Purchases',
                  onTap: () async {
                    // Plus.restore() returns the user-facing outcome; dropping
                    // it made this tile silent on failure and on success.
                    final message = await ref
                        .read(plusProvider.notifier)
                        .restore();
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
                ),
                SettingsTile(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Manage Subscription',
                  onTap: () =>
                      _open('https://apps.apple.com/account/subscriptions'),
                ),
              ],
            ),
            SettingsSection(
              title: 'ACCOUNT & SYNC',
              children: [
                SettingsTile(
                  icon: Icons.account_circle_outlined,
                  label: 'Sign In / Account',
                  value: user?.email ?? 'Guest',
                  onTap: () => context.push('/account'),
                ),
                SettingsTile(
                  icon: Icons.cloud_sync_outlined,
                  label: 'Sync Now',
                  value: user == null
                      ? 'Sign in'
                      : (settings.syncEnabled ? 'Enabled' : 'Manual'),
                  onTap: () async {
                    if (user == null) {
                      context.push('/account');
                      return;
                    }
                    try {
                      final result = await ref
                          .read(cloudSyncServiceProvider)
                          .syncLibrary(settings);
                      if (result.restoredSettings != null) {
                        await ref
                            .read(settingsProvider.notifier)
                            .update((_) => result.restoredSettings!);
                      }
                      await ref.read(signatureStoreProvider).syncCloud();
                      ref.read(documentsProvider.notifier).refresh();
                      ref.read(foldersProvider.notifier).refresh();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cloud sync complete: ${result.uploaded} uploaded, ${result.restored} restored.',
                            ),
                          ),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              userMessageFor(
                                error,
                                fallback:
                                    'Cloud sync could not be completed. Check your connection and try again.',
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                SettingsToggleTile(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Auto Upload',
                  value: settings.autoUploadEnabled,
                  onChanged: (enabled) async {
                    if (user == null) {
                      context.push('/account');
                      return;
                    }
                    if (enabled && !plusActive) {
                      context.push('/paywall');
                      return;
                    }
                    await ref
                        .read(settingsProvider.notifier)
                        .update(
                          (current) => current.copyWith(
                            syncEnabled: enabled || current.syncEnabled,
                            autoUploadEnabled: enabled,
                          ),
                        );
                  },
                ),
              ],
            ),
            SettingsSection(
              title: 'SUPPORT',
              children: [
                SettingsTile(
                  icon: Icons.support_agent_rounded,
                  label: plusActive ? 'Priority Support' : 'Contact Us',
                  onTap: () => context.push('/support'),
                ),
                SettingsTile(
                  icon: Icons.star_outline_rounded,
                  label: 'Rate App',
                  onTap: () =>
                      _open('${AppConstants.appStoreUrl}?action=write-review'),
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
    final plusActive = ref.read(plusProvider).isActive;
    var index = values.indexOf(current);
    ScanFilter next;
    do {
      index = (index + 1) % values.length;
      next = values[index];
    } while (next.isPlus && !plusActive && next != current);
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

  void _cycleCameraMode(WidgetRef ref, CameraMode current) {
    const modes = [CameraMode.document, CameraMode.text, CameraMode.book];
    final index = modes.indexOf(current);
    final next = modes[(index < 0 ? 0 : index + 1) % modes.length];
    ref
        .read(settingsProvider.notifier)
        .update((settings) => settings.copyWith(defaultCameraMode: next));
  }

  void _cycleOcrBundle(WidgetRef ref, String current) {
    const bundles = ['latin', 'western', 'cjk'];
    final index = bundles.indexOf(current);
    final next = bundles[(index < 0 ? 0 : index + 1) % bundles.length];
    ref
        .read(settingsProvider.notifier)
        .update((settings) => settings.copyWith(ocrLanguageBundle: next));
  }

  void _cycleFileName(WidgetRef ref, String current) {
    const patterns = FileNameFormats.all;
    final index = patterns.indexOf(FileNameFormats.normalize(current));
    final next = patterns[(index < 0 ? 0 : index + 1) % patterns.length];
    ref
        .read(settingsProvider.notifier)
        .update((settings) => settings.copyWith(defaultFileNameFormat: next));
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
          gradient: LinearGradient(colors: [colors.accent, colors.accentDeep]),
          borderRadius: AppShapes.cardRadius,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 28,
              semanticLabel: 'Plus',
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Plus',
                    style: AppTypography.title(Colors.white),
                  ),
                  Text(
                    'Reusable signatures & priority support',
                    style: AppTypography.caption(
                      Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              semanticLabel: 'Open paywall',
            ),
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
          Icon(
            Icons.verified_rounded,
            color: colors.success,
            size: 24,
            semanticLabel: 'Plus active',
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Plus is active',
            style: AppTypography.bodyMedium(colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
