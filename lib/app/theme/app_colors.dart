import 'dart:ui';

/// Palette from DESIGN_BRIEF.md — Jira SUBAPPS-129 §5 named colors, hexes
/// committed in the brief. The dark indigo shell is constant across themes;
/// paper surfaces flip between light and dark variants.
abstract class AppColors {
  // Shell (constant in both themes)
  static const Color deepIndigo = Color(0xFF26214F);
  static const Color indigoDeeper = Color(0xFF1C1840);
  static const Color indigoElevated = Color(0xFF38316B);
  static const Color indigoPressed = Color(0xFF443C7E);

  // Accent — reserved for scan action, primary CTAs, Plus, progress
  static const Color scanOrange = Color(0xFFFF7A2E);
  static const Color scanOrangeDeep = Color(0xFFF2600F);

  // Paper surfaces — light theme
  static const Color paperWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFF4F5F9);
  static const Color toolCard = Color(0xFFF0F1F6);
  static const Color hairlineLight = Color(0xFFE4E4EE);

  // Paper surfaces — dark theme variants
  static const Color paperDark = Color(0xFF211D48);
  static const Color paperDarkBg = Color(0xFF17143A);
  static const Color toolCardDark = Color(0xFF2A2558);
  static const Color hairlineDark = Color(0xFF39336C);

  // Text
  static const Color navyText = Color(0xFF1C1B3A);
  static const Color mutedSlate = Color(0xFF6E6D8A);
  static const Color textLightPrimary = Color(0xFFF2F1FA);
  static const Color mutedLavender = Color(0xFFA9A5CE);

  // Functional coding (Swiss archetype)
  static const Color successGreen = Color(0xFF2FB47C);
  static const Color dangerRed = Color(0xFFE5484D);
}
