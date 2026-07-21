import 'package:flutter/material.dart';

import 'package:scanpdf/app/theme/app_theme.dart';

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);

  /// App tokens — the single access point for all colors.
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>()!;

  TextTheme get text => Theme.of(this).textTheme;

  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
