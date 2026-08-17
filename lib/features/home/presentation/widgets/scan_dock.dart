import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/home/presentation/providers/import_provider.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_session_provider.dart';
import 'package:scanpdf/features/tools/presentation/tools_sheet.dart';

/// The floating pill action bar (Jira §10): Tools · Camera · Photos.
class ScanDock extends ConsumerWidget {
  const ScanDock({super.key});

  Future<void> _importPhotos(BuildContext context, WidgetRef ref) async {
    final added = await ref.read(importControllerProvider).importPhotos();
    if (added > 0 && context.mounted) context.push('/review');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.md,
      ),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.shellElevated,
          borderRadius: AppShapes.pillRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _DockButton(
              icon: Icons.grid_view_rounded,
              label: 'Tools',
              onTap: () => ToolsSheet.show(context),
            ),
            _CameraButton(
              onTap: () {
                Haptics.tap();
                ref.read(scanSessionProvider.notifier).start();
                context.push('/camera');
              },
            ),
            _DockButton(
              icon: Icons.photo_library_outlined,
              label: 'Photos',
              onTap: () => _importPhotos(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressableTap(
      style: PressStyle.dim,
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.onShell, size: 24, semanticLabel: label),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.label(colors.onShellMuted)),
          ],
        ),
      ),
    );
  }
}

/// The big orange scan button — raised above the pill.
class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Transform.translate(
      offset: const Offset(0, -14),
      child: PressableTap(
        onTap: onTap,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.accent, colors.accentDeep],
            ),
            border: Border.all(color: colors.shellBg, width: 4),
          ),
          child: const Icon(
            Icons.photo_camera_rounded,
            color: Colors.white,
            size: 28,
            semanticLabel: 'Scan with camera',
          ),
        ),
      ),
    );
  }
}
