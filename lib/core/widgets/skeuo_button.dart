import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/neo_shadows.dart';
import '../../core/utils/haptics.dart';

/// Primary CTA button re-skinned to Playful Neo-Brutal + Dark.
/// - 2px ink border
/// - Hard offset shadow (md by default)
/// - Press = translate (+2, +2) and shadow collapse
class SkeuoButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? color;
  final Color? textColor;

  const SkeuoButton({
    super.key,
    required this.text,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.color,
    this.textColor,
  });

  @override
  State<SkeuoButton> createState() => _SkeuoButtonState();
}

class _SkeuoButtonState extends State<SkeuoButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    Haptics.light();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    Haptics.medium();
    widget.onTap!();
  }

  void _handleTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null || widget.isLoading;

    // Default primary = gold; caller can override via `color`.
    final bg = isDisabled
        ? AppColors.textTertiary(context)
        : (widget.color ?? AppColors.gold);

    final fg = widget.textColor ??
        (_isGoldish(bg) ? AppColors.neoSurface : AppColors.neoInk);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        transform:
            _isPressed ? Matrix4.translationValues(2, 2, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.cardBorder(context, strong: true),
            width: 2.0,
          ),
          boxShadow: isDisabled || _isPressed
              ? const []
              : NeoShadows.md(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: fg.withOpacity(0.85),
                ),
              )
            else ...[
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: fg),
                const SizedBox(width: 10),
              ],
              Text(
                widget.text,
                style: AppTypography.buttonLg.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isGoldish(Color c) {
    return c == AppColors.gold || c == AppColors.goldDeep;
  }
}
