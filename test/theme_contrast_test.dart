import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scanpdf/app/theme/app_theme.dart';

/// Guards the button and field colours against the backgrounds they actually
/// render on.
///
/// The tool screens (Translate, Count, Measure, QR, Expense) put Material
/// buttons on the dark shell — and Measure on pure black. The theme used to
/// define no button themes at all, so buttons inherited `primary` (deep
/// indigo) and rendered dark-on-dark, with disabled states collapsing to
/// onSurface at 12%/38% opacity. On screen they looked switched off, which is
/// exactly how the bug was reported: "the button was not even clicking".
void main() {
  /// WCAG 2.1 relative luminance.
  double relativeLuminance(Color c) {
    double channel(double v) {
      final s = v / 255.0;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4) as double;
    }

    return 0.2126 * channel(c.r * 255) +
        0.7152 * channel(c.g * 255) +
        0.0722 * channel(c.b * 255);
  }

  /// Flattens a possibly translucent foreground over its background first —
  /// a disabled colour at 30% alpha is what the eye actually sees.
  Color flatten(Color fg, Color bg) {
    final a = fg.a;
    return Color.fromARGB(
      255,
      ((fg.r * 255 * a) + (bg.r * 255 * (1 - a))).round(),
      ((fg.g * 255 * a) + (bg.g * 255 * (1 - a))).round(),
      ((fg.b * 255 * a) + (bg.b * 255 * (1 - a))).round(),
    );
  }

  double contrast(Color fg, Color bg) {
    final f = relativeLuminance(flatten(fg, bg));
    final b = relativeLuminance(bg);
    final hi = math.max(f, b);
    final lo = math.min(f, b);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// WCAG 2.1 SC 1.4.11 requires 3:1 for non-text UI components. Disabled
  /// controls are exempt from the letter of the rule, but a control the user
  /// cannot see at all is indistinguishable from a broken one, so hold them
  /// to the same bar.
  const minRatio = 3.0;

  // Every background a Material button is actually placed on in this app.
  final backgrounds = <String, Color>{
    'shell (dark indigo)': const Color(0xFF1C1840),
    'measure screen (black)': Colors.black,
  };

  for (final entry in {
    'dark': AppTheme.dark(),
    'light': AppTheme.light(),
  }.entries) {
    final themeName = entry.key;
    final theme = entry.value;

    group('$themeName theme', () {
      test('filled button is visible in both enabled and disabled states', () {
        final style = theme.filledButtonTheme.style!;
        for (final states in [
          <WidgetState>{},
          {WidgetState.disabled},
        ]) {
          final bg = style.backgroundColor!.resolve(states)!;
          final fg = style.foregroundColor!.resolve(states)!;
          for (final surface in backgrounds.entries) {
            expect(
              contrast(bg, surface.value),
              greaterThanOrEqualTo(minRatio),
              reason:
                  'FilledButton fill ($states) is invisible on ${surface.key}',
            );
          }
          // Label must be readable against its own fill.
          expect(
            contrast(fg, flatten(bg, backgrounds.values.first)),
            greaterThanOrEqualTo(minRatio),
            reason: 'FilledButton label ($states) is unreadable on its fill',
          );
        }
      });

      test('outlined and text buttons are visible on every background', () {
        final styles = {
          'OutlinedButton': theme.outlinedButtonTheme.style!,
          'TextButton': theme.textButtonTheme.style!,
        };
        for (final s in styles.entries) {
          for (final states in [
            <WidgetState>{},
            {WidgetState.disabled},
          ]) {
            final fg = s.value.foregroundColor!.resolve(states)!;
            for (final surface in backgrounds.entries) {
              expect(
                contrast(fg, surface.value),
                greaterThanOrEqualTo(minRatio),
                reason:
                    '${s.key} label ($states) is invisible on ${surface.key}',
              );
            }
          }
        }
      });

      test('buttons do not fall back to the dark seed primary', () {
        // The original defect: no button themes, so everything inherited
        // colorScheme.primary (deep indigo) on a deep indigo shell.
        final filled = theme.filledButtonTheme.style!.backgroundColor!.resolve(
          <WidgetState>{},
        )!;
        expect(
          filled.toARGB32(),
          isNot(theme.colorScheme.primary.toARGB32()),
          reason: 'FilledButton still uses the dark seed primary',
        );
      });

      test('field label and hint are readable on the paper surface', () {
        final deco = theme.inputDecorationTheme;
        final surface = theme.colorScheme.surface;
        for (final style in [deco.labelStyle, deco.hintStyle]) {
          expect(style, isNotNull);
          expect(
            contrast(style!.color!, surface),
            greaterThanOrEqualTo(minRatio),
            reason: 'input label/hint is washed out on the surface',
          );
        }
      });
    });
  }
}
