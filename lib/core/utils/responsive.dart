import 'package:flutter/widgets.dart';

import 'package:scanpdf/core/constants/app_constants.dart';

abstract class Responsive {
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppConstants.mobileBreakpoint;

  /// Grid column count for the document library.
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppConstants.tabletBreakpoint) return 4;
    if (width >= AppConstants.mobileBreakpoint) return 3;
    return 2;
  }
}
