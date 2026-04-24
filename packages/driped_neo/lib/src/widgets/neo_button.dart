import 'package:flutter/material.dart';

import '../neo_colors.dart';
import '../neo_motion.dart';
import '../neo_radius.dart';
import '../neo_shadows.dart';
import '../neo_typography.dart';

enum NeoButtonVariant { primary, secondary, ghost, danger }
enum NeoButtonSize { sm, md, lg }

/// Playful Neo-Brutal button. Press = slam (+2, +2), shadow collapses.
class NeoButton extends StatefulWidget {
  final Widget? icon;
  final String label;
  final VoidCallback? onPressed;
  final NeoButtonVariant variant;
  final NeoButtonSize size;
  final bool fullWidth;
  final bool loading;

  const NeoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = NeoButtonVariant.primary,
    this.size = NeoButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
  });

  const NeoButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = NeoButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
  }) : variant = NeoButtonVariant.secondary;

  const NeoButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = NeoButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
  }) : variant = NeoButtonVariant.ghost;

  const NeoButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = NeoButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
  }) : variant = NeoButtonVariant.danger;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final padding = _padding();
    final (bg, fg, shadow) = _colorPair(context);

    final shadowNow = _pressed
        ? const <BoxShadow>[]
        : (_hover && enabled ? NeoShadows.hover(shadow) : shadow);

    Offset translate = Offset.zero;
    if (_pressed) {
      translate = NeoMotion.pressSlam;
    } else if (_hover && enabled) {
      translate = NeoMotion.hoverLift;
    }

    final content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (widget.icon != null)
          IconTheme.merge(
            data: IconThemeData(color: fg, size: _iconSize()),
            child: widget.icon!,
          ),
        if (widget.icon != null || widget.loading) const SizedBox(width: 8),
        Text(
          widget.label,
          style: NeoTypography.bodyBold(color: fg).copyWith(fontSize: _fontSize()),
        ),
      ],
    );

    final button = AnimatedContainer(
      duration: _pressed ? NeoMotion.fast : NeoMotion.base,
      curve: NeoMotion.easeOut,
      transform: Matrix4.translationValues(translate.dx, translate.dy, 0),
      padding: padding,
      decoration: BoxDecoration(
        color: enabled ? bg : NeoColors.inkGhost(context).withValues(alpha: 0.3),
        borderRadius: NeoRadius.borderLg,
        border: Border.all(
          color: NeoColors.border(context),
          width: enabled ? 2 : 1.5,
        ),
        boxShadow: enabled ? shadowNow : const [],
      ),
      child: Opacity(opacity: enabled ? 1 : 0.5, child: content),
    );

    final wrapped = widget.fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;

    if (!enabled) return wrapped;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: wrapped,
      ),
    );
  }

  EdgeInsets _padding() {
    switch (widget.size) {
      case NeoButtonSize.sm: return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case NeoButtonSize.md: return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case NeoButtonSize.lg: return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }
  }

  double _fontSize() {
    switch (widget.size) {
      case NeoButtonSize.sm: return 13;
      case NeoButtonSize.md: return 14;
      case NeoButtonSize.lg: return 16;
    }
  }

  double _iconSize() {
    switch (widget.size) {
      case NeoButtonSize.sm: return 14;
      case NeoButtonSize.md: return 16;
      case NeoButtonSize.lg: return 18;
    }
  }

  (Color bg, Color fg, List<BoxShadow> shadow) _colorPair(BuildContext c) {
    switch (widget.variant) {
      case NeoButtonVariant.primary:
        return (NeoColors.gold(c), NeoColors.darkSurface, NeoShadows.md(c));
      case NeoButtonVariant.secondary:
        return (NeoColors.surface(c), NeoColors.ink(c), NeoShadows.sm(c));
      case NeoButtonVariant.ghost:
        return (Colors.transparent, NeoColors.ink(c), const <BoxShadow>[]);
      case NeoButtonVariant.danger:
        return (NeoColors.danger(c), NeoColors.cream(c), NeoShadows.md(c));
    }
  }
}
