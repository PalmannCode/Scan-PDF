import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:scanpdf/app/theme/app_colors.dart';
import 'package:scanpdf/app/theme/app_typography.dart';

/// App-specific tokens exposed through the theme. The dark indigo shell
/// stays constant; paper surfaces flip between the two themes.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.shellBg,
    required this.shellBgDeep,
    required this.shellElevated,
    required this.shellPressed,
    required this.onShell,
    required this.onShellMuted,
    required this.paperBg,
    required this.paperCard,
    required this.toolCard,
    required this.textPrimary,
    required this.textSecondary,
    required this.hairline,
    required this.accent,
    required this.accentDeep,
    required this.success,
    required this.danger,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color shellBg;
  final Color shellBgDeep;
  final Color shellElevated;
  final Color shellPressed;
  final Color onShell;
  final Color onShellMuted;
  final Color paperBg;
  final Color paperCard;
  final Color toolCard;
  final Color textPrimary;
  final Color textSecondary;
  final Color hairline;
  final Color accent;
  final Color accentDeep;
  final Color success;
  final Color danger;
  final Color shimmerBase;
  final Color shimmerHighlight;

  static const light = AppColorsExtension(
    shellBg: AppColors.deepIndigo,
    shellBgDeep: AppColors.indigoDeeper,
    shellElevated: AppColors.indigoElevated,
    shellPressed: AppColors.indigoPressed,
    onShell: Colors.white,
    onShellMuted: AppColors.mutedLavender,
    paperBg: AppColors.softGrey,
    paperCard: AppColors.paperWhite,
    toolCard: AppColors.toolCard,
    textPrimary: AppColors.navyText,
    textSecondary: AppColors.mutedSlate,
    hairline: AppColors.hairlineLight,
    accent: AppColors.scanOrange,
    accentDeep: AppColors.scanOrangeDeep,
    success: AppColors.successGreen,
    danger: AppColors.dangerRed,
    shimmerBase: Color(0xFFE9EAF2),
    shimmerHighlight: Color(0xFFFDF3EC),
  );

  static const dark = AppColorsExtension(
    shellBg: AppColors.deepIndigo,
    shellBgDeep: AppColors.indigoDeeper,
    shellElevated: AppColors.indigoElevated,
    shellPressed: AppColors.indigoPressed,
    onShell: Colors.white,
    onShellMuted: AppColors.mutedLavender,
    paperBg: AppColors.paperDarkBg,
    paperCard: AppColors.paperDark,
    toolCard: AppColors.toolCardDark,
    textPrimary: AppColors.textLightPrimary,
    textSecondary: AppColors.mutedLavender,
    hairline: AppColors.hairlineDark,
    accent: AppColors.scanOrange,
    accentDeep: AppColors.scanOrangeDeep,
    success: AppColors.successGreen,
    danger: AppColors.dangerRed,
    shimmerBase: Color(0xFF2A2558),
    shimmerHighlight: Color(0xFF3D3670),
  );

  @override
  AppColorsExtension copyWith({Color? accent}) => this;

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorsExtension(
      shellBg: l(shellBg, other.shellBg),
      shellBgDeep: l(shellBgDeep, other.shellBgDeep),
      shellElevated: l(shellElevated, other.shellElevated),
      shellPressed: l(shellPressed, other.shellPressed),
      onShell: l(onShell, other.onShell),
      onShellMuted: l(onShellMuted, other.onShellMuted),
      paperBg: l(paperBg, other.paperBg),
      paperCard: l(paperCard, other.paperCard),
      toolCard: l(toolCard, other.toolCard),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      hairline: l(hairline, other.hairline),
      accent: l(accent, other.accent),
      accentDeep: l(accentDeep, other.accentDeep),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      shimmerBase: l(shimmerBase, other.shimmerBase),
      shimmerHighlight: l(shimmerHighlight, other.shimmerHighlight),
    );
  }
}

abstract class AppTheme {
  static ThemeData light() => _build(AppColorsExtension.light, Brightness.light);
  static ThemeData dark() => _build(AppColorsExtension.dark, Brightness.dark);

  static ThemeData _build(AppColorsExtension c, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.paperBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepIndigo,
        brightness: brightness,
        primary: AppColors.deepIndigo,
        secondary: c.accent,
        surface: c.paperBg,
        error: c.danger,
      ),
      textTheme: AppTypography.textTheme(c.textPrimary, c.textSecondary),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerTheme: DividerThemeData(
        color: c.hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.title(c.textPrimary),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: [c],
    );
  }
}
