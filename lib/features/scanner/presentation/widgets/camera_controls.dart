import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/shared/models/enums.dart';

class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    super.key,
    required this.flash,
    required this.pageCount,
    required this.onClose,
    required this.onFlash,
    required this.onBatchTap,
  });

  final FlashMode flash;
  final int pageCount;
  final VoidCallback onClose;
  final VoidCallback onFlash;
  final VoidCallback onBatchTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final flashIcon = switch (flash) {
      FlashMode.always => Icons.flash_on_rounded,
      FlashMode.auto => Icons.flash_auto_rounded,
      _ => Icons.flash_off_rounded,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          PressableTap(
            style: PressStyle.dim,
            onTap: onClose,
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              semanticLabel: 'Close camera',
            ),
          ),
          const Spacer(),
          PressableTap(
            style: PressStyle.dim,
            onTap: onFlash,
            child: Icon(
              flashIcon,
              color: Colors.white,
              semanticLabel: 'Flash mode',
            ),
          ),
          if (pageCount > 0) ...[
            const SizedBox(width: AppSpacing.lg),
            PressableTap(
              style: PressStyle.dim,
              onTap: onBatchTap,
              child: AnimatedContainer(
                duration: AppMotion.micro,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: AppShapes.pillRadius,
                ),
                child: Text(
                  '$pageCount',
                  style: AppTypography.mono(Colors.white, size: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ScanFilter selected;
  final ValueChanged<ScanFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: ScanFilter.values.length,
        itemBuilder: (context, index) {
          final filter = ScanFilter.values[index];
          final active = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: PressableTap(
              style: PressStyle.dim,
              onTap: () => onSelected(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? colors.accent
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: AppShapes.pillRadius,
                ),
                child: Text(
                  filter.label,
                  style: AppTypography.bodyMedium(
                    active ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CameraModeBar extends StatelessWidget {
  const CameraModeBar({
    super.key,
    required this.mode,
    required this.filter,
    required this.onMode,
    required this.onFilterTap,
  });

  final CameraMode mode;
  final ScanFilter filter;
  final ValueChanged<CameraMode> onMode;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          PressableTap(
            style: PressStyle.dim,
            onTap: onFilterTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: AppShapes.pillRadius,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: colors.accent,
                    semanticLabel: 'Filter',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    filter.label,
                    style: AppTypography.caption(Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          for (final m in CameraMode.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: PressableTap(
                style: PressStyle.dim,
                onTap: () => onMode(m),
                child: AnimatedContainer(
                  duration: AppMotion.standard,
                  curve: AppMotion.enter,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: m == mode
                        ? colors.shellElevated
                        : Colors.transparent,
                    borderRadius: AppShapes.pillRadius,
                  ),
                  child: Text(
                    m.label,
                    style: AppTypography.bodyMedium(
                      m == mode ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CameraShutterBar extends StatelessWidget {
  const CameraShutterBar({
    super.key,
    required this.capturing,
    required this.hasPages,
    required this.onShutter,
    required this.onGallery,
    required this.onDone,
  });

  final bool capturing;
  final bool hasPages;
  final VoidCallback onShutter;
  final VoidCallback onGallery;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PressableTap(
            style: PressStyle.dim,
            onTap: onGallery,
            child: const Icon(
              Icons.photo_library_outlined,
              color: Colors.white,
              size: 28,
              semanticLabel: 'Import from gallery',
            ),
          ),
          PressableTap(
            onTap: capturing ? null : onShutter,
            enabled: !capturing,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: capturing ? colors.accentDeep : colors.accent,
                ),
              ),
            ),
          ),
          PressableTap(
            style: PressStyle.dim,
            enabled: hasPages,
            onTap: hasPages ? onDone : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasPages
                    ? colors.success
                    : Colors.white.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.check_rounded,
                color: hasPages ? Colors.white : Colors.white38,
                semanticLabel: 'Finish batch',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
