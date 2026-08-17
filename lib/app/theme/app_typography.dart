import 'package:flutter/material.dart';

/// Typography from DESIGN_BRIEF.md axis 2: Archivo display + body,
/// IBM Plex Mono for ALL numerals and metadata (page counts, sizes, dates).
abstract class AppTypography {
  static TextStyle display(Color color) => TextStyle(
    fontFamily: 'Archivo',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.15,
    color: color,
  );

  static TextStyle headline(Color color) => TextStyle(
    fontFamily: 'Archivo',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
    color: color,
  );

  static TextStyle title(Color color) => TextStyle(
    fontFamily: 'Archivo',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: color,
  );

  static TextStyle body(Color color) => TextStyle(
    fontFamily: 'Archivo',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: color,
  );

  static TextStyle bodyMedium(Color color) => TextStyle(
    fontFamily: 'Archivo',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle caption(Color color) => TextStyle(
    fontFamily: 'Archivo',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: color,
  );

  static TextStyle label(Color color) => TextStyle(
    fontFamily: 'Archivo',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: color,
  );

  /// Numerals and metadata ALWAYS render in Plex Mono (hard rule).
  static TextStyle mono(Color color, {double size = 13}) => TextStyle(
    fontFamily: 'IBM Plex Mono',
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle monoLarge(Color color) => TextStyle(
    fontFamily: 'IBM Plex Mono',
    fontSize: 34,
    fontWeight: FontWeight.w600,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
    displaySmall: display(primary),
    headlineSmall: headline(primary),
    titleMedium: title(primary),
    bodyMedium: body(primary),
    bodySmall: caption(secondary),
    labelSmall: label(secondary),
  );
}
