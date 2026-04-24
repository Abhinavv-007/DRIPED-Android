import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/haptics.dart';

/// Neo-brutalist button. Hard offset shadow, zero border radius,
/// physical press — the button translates into the shadow on tap.
class NeoButton extends StatefulWidget {
  final String label;
  final IconData? leading;
  final IconData? trailing;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Color shadowColour;
  final Offset shadowOffset;
  final bool fullWidth;
  final double height;
  final bool loading;

  const NeoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.background = AppColors.gold,
    this.foreground = AppColors.ink,
    this.shadowColour = AppColors.shadowInk,
    this.shadowOffset = const Offset(5, 5),
    this.fullWidth = true,
    this.height = 56,
    this.loading = false,
  });

  const NeoButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.fullWidth = true,
    this.height = 56,
    this.loading = false,
  })  : background = Colors.transparent,
        foreground = AppColors.textHi,
        shadowColour = Colors.transparent,
        shadowOffset = Offset.zero;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;

  void _down(_) {
    if (widget.onPressed == null || widget.loading) return;
    setState(() => _pressed = true);
    Haptics.tap();
  }

  void _up(_) {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isGhost = widget.background == Colors.transparent;
    final disabled = widget.onPressed == null || widget.loading;

    final textStyle = isGhost
        ? AppTypography.buttonMd.copyWith(
            color: widget.foreground,
            decoration: TextDecoration.underline,
            decorationThickness: 2,
          )
        : AppTypography.buttonLg.copyWith(color: widget.foreground);

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: widget.loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    child: SizedBox(
                      width: 30,
                      height: 20,
                      child: _PulsingDot(color: widget.foreground),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textStyle,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              key: const ValueKey('idle'),
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.leading != null) ...[
                  Icon(widget.leading, size: 18, color: widget.foreground),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 10),
                  Icon(widget.trailing, size: 18, color: widget.foreground),
                ],
              ],
            ),
    );

    if (isGhost) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled
            ? null
            : () {
                Haptics.tap();
                widget.onPressed!();
              },
        child: SizedBox(
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          child: Center(child: content),
        ),
      );
    }

    final translate = _pressed ? widget.shadowOffset : Offset.zero;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: (d) {
        _up(d);
        if (!disabled) widget.onPressed!();
      },
      onTapCancel: () => _up(null),
      child: SizedBox(
        height: widget.height + widget.shadowOffset.dy.abs(),
        width: widget.fullWidth ? double.infinity : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: widget.shadowOffset.dx,
              top: widget.shadowOffset.dy,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.shadowColour,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              transform:
                  Matrix4.translationValues(translate.dx, translate.dy, 0),
              width: double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                color: disabled
                    ? widget.background.withOpacity(0.5)
                    : widget.background,
                border: Border.all(color: AppColors.shadowInk, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              child: Center(
                child: DefaultTextStyle.merge(
                  style: textStyle,
                  child: content,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 80),
                  opacity: _pressed ? 0.1 : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.shadowInk,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeOut(delay: (i * 200).ms, duration: 400.ms)
              .then()
              .fadeIn(duration: 400.ms),
      ],
    );
  }
}
