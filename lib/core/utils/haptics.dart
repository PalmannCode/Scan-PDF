import 'package:flutter/services.dart';

/// Haptic vocabulary: light on taps, medium on destructive, heavy on success.
abstract class Haptics {
  static void tap() => HapticFeedback.lightImpact();
  static void destructive() => HapticFeedback.mediumImpact();
  static void success() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();
}
