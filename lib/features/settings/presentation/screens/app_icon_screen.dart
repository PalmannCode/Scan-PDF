import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/errors/user_message.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/services/app_icon_service.dart';

class AppIconScreen extends ConsumerStatefulWidget {
  const AppIconScreen({super.key});

  @override
  ConsumerState<AppIconScreen> createState() => _AppIconScreenState();
}

class _AppIconScreenState extends ConsumerState<AppIconScreen> {
  String? _changing;
  String? _error;

  Future<void> _select(AppIconOption option) async {
    final plus = ref.read(plusProvider).isActive;
    if (option.plusOnly && !plus) {
      context.push('/paywall');
      return;
    }
    setState(() {
      _changing = option.id;
      _error = null;
    });
    try {
      await ref.read(appIconServiceProvider).setIcon(option);
      await ref
          .read(settingsProvider.notifier)
          .update((settings) => settings.copyWith(appIcon: option.id));
      await ref
          .read(analyticsServiceProvider)
          .track(
            'app_icon_changed',
            properties: {'app_icon': option.id, 'screen_name': 'app_icon'},
          );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = userMessageFor(
            error,
            fallback: 'The app icon could not be changed on this device.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = ref.watch(settingsProvider).appIcon;
    final plus = ref.watch(plusProvider.select((state) => state.isActive));
    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          onTap: () => context.pop(),
          child: Icon(Icons.close_rounded, color: colors.textPrimary),
        ),
        title: Text('App Icon', style: AppTypography.title(colors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Choose how Scan PDF appears on your Home Screen.',
              style: AppTypography.body(colors.textSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: AppTypography.caption(colors.danger)),
            ],
            const SizedBox(height: AppSpacing.xl),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.82,
              children: [
                for (final option in AppIconService.options)
                  PressableTap(
                    onTap: _changing == null ? () => _select(option) : null,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.paperCard,
                        borderRadius: AppShapes.cardRadius,
                        border: Border.all(
                          color: selected == option.id
                              ? colors.accent
                              : colors.hairline,
                          width: selected == option.id ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppShapes.thumbnailRadius,
                              child: Image.asset(option.assetPath),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (selected == option.id)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: colors.accent,
                                  size: 18,
                                ),
                              if (selected == option.id)
                                const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  option.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium(
                                    colors.textPrimary,
                                  ),
                                ),
                              ),
                              if (option.plusOnly && !plus) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: colors.accent,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          if (_changing == option.id)
                            const Padding(
                              padding: EdgeInsets.only(top: AppSpacing.xs),
                              child: LinearProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
