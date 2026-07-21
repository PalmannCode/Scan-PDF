import 'package:flutter/material.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/core/utils/haptics.dart';

/// Press feedback styles allowed by the Design Brief (axis 6):
/// [PressStyle.dim] for dark-shell chrome, [PressStyle.scale] for
/// light-surface cards and CTAs. No glow, no squash, no offset press.
enum PressStyle { dim, scale }

/// Wraps every tappable element in the app. Always fires a light haptic.
class PressableTap extends StatefulWidget {
  const PressableTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.style = PressStyle.scale,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final PressStyle style;
  final bool enabled;

  @override
  State<PressableTap> createState() => _PressableTapState();
}

class _PressableTapState extends State<PressableTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.micro,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _interactive => widget.enabled && widget.onTap != null;

  void _down(_) {
    if (_interactive) _controller.value = 1;
  }

  void _up() => _controller.reverse();

  void _handleTap() {
    if (!_interactive) return;
    Haptics.tap();
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      onTap: _handleTap,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              Haptics.selection();
              widget.onLongPress!.call();
            },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_controller.value);
          switch (widget.style) {
            case PressStyle.dim:
              return Opacity(opacity: 1 - 0.38 * t, child: child);
            case PressStyle.scale:
              return Transform.scale(scale: 1 - 0.03 * t, child: child);
          }
        },
        child: widget.child,
      ),
    );
  }
}
