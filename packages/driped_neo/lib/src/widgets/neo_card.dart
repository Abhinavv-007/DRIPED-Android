import 'package:flutter/material.dart';

import '../neo_colors.dart';
import '../neo_motion.dart';
import '../neo_radius.dart';
import '../neo_shadows.dart';

/// Playful Neo-Brutal card. 2px border, hard offset shadow, lifts on hover.
class NeoCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final Color? shadowColor;
  final VoidCallback? onTap;
  final NeoCardVariant variant;

  const NeoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.background,
    this.shadowColor,
    this.onTap,
    this.variant = NeoCardVariant.raised,
  });

  /// Flat \u2014 small shadow, doesn't lift.
  const NeoCard.flat({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background,
    this.shadowColor,
    this.onTap,
  }) : variant = NeoCardVariant.flat;

  /// Accent \u2014 big shadow in gold, for CTAs.
  const NeoCard.accent({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.background,
    this.shadowColor,
    this.onTap,
  }) : variant = NeoCardVariant.accent;

  @override
  State<NeoCard> createState() => _NeoCardState();
}

enum NeoCardVariant { raised, flat, accent }

class _NeoCardState extends State<NeoCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.background ??
        (widget.variant == NeoCardVariant.flat
            ? NeoColors.surface(context)
            : NeoColors.surfaceRaised(context));

    List<BoxShadow> base;
    switch (widget.variant) {
      case NeoCardVariant.flat:
        base = NeoShadows.sm(context);
        break;
      case NeoCardVariant.accent:
        base = NeoShadows.gold(context);
        break;
      case NeoCardVariant.raised:
        base = NeoShadows.md(context);
        break;
    }

    final shadow = widget.shadowColor != null
        ? [BoxShadow(color: widget.shadowColor!, offset: const Offset(4, 4))]
        : base;

    final shadowNow = _pressed
        ? const <BoxShadow>[]
        : (_hover && widget.onTap != null ? NeoShadows.hover(shadow) : shadow);

    Offset translate = Offset.zero;
    if (_pressed) {
      translate = NeoMotion.pressSlam;
    } else if (_hover && widget.onTap != null) {
      translate = NeoMotion.hoverLift;
    }

    final decorated = AnimatedContainer(
      duration: _pressed ? NeoMotion.fast : NeoMotion.base,
      curve: NeoMotion.easeOut,
      transform: Matrix4.translationValues(translate.dx, translate.dy, 0),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: NeoRadius.borderXl,
        border: Border.all(
          color: NeoColors.border(context),
          width: NeoBorderWidth.base,
        ),
        boxShadow: shadowNow,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return decorated;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: decorated,
      ),
    );
  }
}
