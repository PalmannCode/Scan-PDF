import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:scanpdf/app/theme/app_motion.dart';

/// Mechanical stagger from the brief: fade + 6px rise, 40ms/item, no scale.
extension StaggeredEntrance on Widget {
  Widget staggered(int index, {Duration? base}) => animate()
      .fadeIn(
        delay: (base ?? Duration.zero) + AppMotion.stagger * index,
        duration: AppMotion.standard,
        curve: AppMotion.enter,
      )
      .moveY(
        begin: 6,
        end: 0,
        delay: (base ?? Duration.zero) + AppMotion.stagger * index,
        duration: AppMotion.standard,
        curve: AppMotion.enter,
      );
}

/// Column whose children enter with the staggered gesture.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++) children[i].staggered(i),
      ],
    );
  }
}
