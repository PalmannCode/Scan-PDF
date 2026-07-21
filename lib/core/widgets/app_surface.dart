import 'package:flutter/material.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';

/// Card/container primitive. Shape language from the brief:
/// light surfaces = paper card + hairline border + optional soft shadow;
/// dark-shell surfaces = lighter indigo fill, no border, no shadow.
enum SurfaceVariant {
  /// Content card on paper background.
  primary,

  /// Nested/inset surface (tool cards, secondary rows).
  secondary,

  /// Selected/featured: accent left edge + slightly lifted.
  emphasis,

  /// Elevated fill on the dark indigo shell.
  shell,
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.variant = SurfaceVariant.primary,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final SurfaceVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = borderRadius ?? AppShapes.cardRadius;

    final decoration = switch (variant) {
      SurfaceVariant.primary => BoxDecoration(
          color: colors.paperCard,
          borderRadius: radius,
          border: Border.all(color: colors.hairline),
          boxShadow: AppShapes.softShadow(colors.textPrimary),
        ),
      SurfaceVariant.secondary => BoxDecoration(
          color: colors.toolCard,
          borderRadius: radius,
        ),
      SurfaceVariant.emphasis => BoxDecoration(
          color: colors.paperCard,
          borderRadius: radius,
          border: Border.all(color: colors.accent, width: 1.5),
          boxShadow: AppShapes.softShadow(colors.accentDeep),
        ),
      SurfaceVariant.shell => BoxDecoration(
          color: colors.shellElevated,
          borderRadius: radius,
        ),
    };

    final surface = DecoratedBox(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return surface;
    return PressableTap(
      onTap: onTap,
      style: variant == SurfaceVariant.shell
          ? PressStyle.dim
          : PressStyle.scale,
      child: surface,
    );
  }
}
