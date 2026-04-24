import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neo_shadows.dart';
import '../../core/utils/haptics.dart';

class SkeuoCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final VoidCallback? onTap;
  final bool isPressed; // External override if needed
  final double? width;
  final double? height;
  final Color? baseColor;
  final bool emphasised;

  const SkeuoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 16,
    this.onTap,
    this.isPressed = false,
    this.width,
    this.height,
    this.baseColor,
    this.emphasised = false,
  });

  @override
  State<SkeuoCard> createState() => _SkeuoCardState();
}

class _SkeuoCardState extends State<SkeuoCard> {
  bool _isTapping = false;

  bool get _effectivePressed => widget.isPressed || _isTapping;

  @override
  Widget build(BuildContext context) {
    // Neo-brutal: solid fill, 2px ink border, hard offset shadow.
    final Color fill = widget.baseColor ??
        AppColors.cardFill(context, emphasised: widget.emphasised);

    final shadow = widget.emphasised
        ? NeoShadows.md(context)
        : NeoShadows.sm(context);

    Widget body = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      padding: widget.padding,
      width: widget.width,
      height: widget.height,
      // Slam down on press: shadow collapses, element shifts (+2, +2).
      transform: _effectivePressed
          ? Matrix4.translationValues(2, 2, 0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: AppColors.cardBorder(context, strong: true),
          width: 2.0,
        ),
        boxShadow: _effectivePressed ? const [] : shadow,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() => _isTapping = true);
          Haptics.light();
        },
        onTapUp: (_) {
          setState(() => _isTapping = false);
          Haptics.medium();
          widget.onTap!();
        },
        onTapCancel: () {
          if (_isTapping) setState(() => _isTapping = false);
        },
        child: body,
      );
    }

    return body;
  }
}
