import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';

/// Skeleton loader — wrap a skeleton layout that mirrors the real content.
/// Highlight is tinted from the palette (never a plain grey shimmer).
class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.shimmerBase,
      highlightColor: colors.shimmerHighlight,
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

/// Building block for skeleton layouts.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = AppShapes.thumbnail,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
