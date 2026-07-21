import 'package:flutter/animation.dart';

/// Motion personality from DESIGN_BRIEF.md axis 6: mechanical, fast, precise.
/// No springs, no overshoot, no bounce.
abstract class AppMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 180);
  static const Duration sheet = Duration(milliseconds: 240);
  static const Duration beamSweep = Duration(milliseconds: 2800);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve ambient = Curves.easeInOutSine;

  /// Stagger delay per list item.
  static const Duration stagger = Duration(milliseconds: 40);
}
