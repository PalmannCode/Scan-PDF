import 'package:flutter/widgets.dart';

/// Shape language from DESIGN_BRIEF.md axis 3: pill chrome, 28px sheets,
/// 14px cards, hairline rules on light, fill-elevation on dark.
abstract class AppShapes {
  static const double pill = 999;
  static const double sheet = 28;
  static const double card = 14;
  static const double button = 14;
  static const double thumbnail = 10;
  static const double chip = 10;

  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius thumbnailRadius = BorderRadius.all(
    Radius.circular(thumbnail),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );

  /// Soft shadow for light paper sheets only — never on the dark shell.
  static List<BoxShadow> softShadow(Color base) => [
    BoxShadow(
      color: base.withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
