import 'package:flutter/widgets.dart';

import 'package:scanpdf/shared/models/enums.dart';

/// Approximate on-screen previews of the processing filters. The real
/// filter is applied by ScannerService at save time; these matrices are
/// visual stand-ins only.
ColorFilter? filterPreviewFor(ScanFilter filter) {
  const grey = ColorFilter.matrix([
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
  switch (filter) {
    case ScanFilter.original:
      return null;
    case ScanFilter.autoColor:
      return const ColorFilter.matrix([
        1.15,
        0,
        0,
        0,
        -10,
        0,
        1.15,
        0,
        0,
        -10,
        0,
        0,
        1.15,
        0,
        -10,
        0,
        0,
        0,
        1,
        0,
      ]);
    case ScanFilter.grayscale:
      return grey;
    case ScanFilter.blackWhite:
      return const ColorFilter.matrix([
        0.64,
        2.15,
        0.22,
        0,
        -255,
        0.64,
        2.15,
        0.22,
        0,
        -255,
        0.64,
        2.15,
        0.22,
        0,
        -255,
        0,
        0,
        0,
        1,
        0,
      ]);
    case ScanFilter.lighten:
      return const ColorFilter.matrix([
        1.18,
        0,
        0,
        0,
        18,
        0,
        1.18,
        0,
        0,
        18,
        0,
        0,
        1.18,
        0,
        18,
        0,
        0,
        0,
        1,
        0,
      ]);
    case ScanFilter.highContrast:
      return const ColorFilter.matrix([
        1.45,
        0,
        0,
        0,
        -48,
        0,
        1.45,
        0,
        0,
        -48,
        0,
        0,
        1.45,
        0,
        -48,
        0,
        0,
        0,
        1,
        0,
      ]);
  }
}

/// Applies the preview filter (if any) around [child].
class FilterPreview extends StatelessWidget {
  const FilterPreview({super.key, required this.filter, required this.child});

  final ScanFilter filter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorFilter = filterPreviewFor(filter);
    if (colorFilter == null) return child;
    return ColorFiltered(colorFilter: colorFilter, child: child);
  }
}
