import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/neo_shadows.dart';
import '../utils/haptics.dart';
// Kept for legacy API compatibility; not used internally anymore.
// ignore: unused_import
import 'skeuo_card.dart';

/// Legacy GlassCard \u2014 now renders in **Playful Neo-Brutal** style.
/// API unchanged, so every screen using `GlassCard` instantly gets the new look:
///   - 2px ink border
///   - 4px hard-offset shadow (no blur)
///   - Solid surface fill from Neo tokens
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur; // Kept for API compatibility, ignored visually
  final double? width;
  final double? height;
  final Color? tint; // Treated as a slight mixed overlay if provided
  final Color? borderColour; // Ignored largely in neumorphism
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dashedBorder;
  final bool emphasised;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 14,
    this.blur = 18,
    this.width,
    this.height,
    this.tint,
    this.borderColour,
    this.onTap,
    this.onLongPress,
    this.dashedBorder = false,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    // If it's effectively just a card, we can reuse SkeuoCard internally if onTap is present
    // but building it manually allows more flexibility for dashed border & long press.
    
    final r = BorderRadius.circular(radius);
    final baseFill = AppColors.cardFill(context, emphasised: emphasised);

    // Blend tint slightly if provided, else use the solid Neo surface.
    final fill = tint != null
        ? Color.alphaBlend(tint!.withOpacity(0.14), baseFill)
        : baseFill;

    // Neo-brutal: always solid ink border + single hard offset shadow.
    final borderColor =
        borderColour ?? AppColors.cardBorder(context, strong: true);
    final shadow = emphasised
        ? NeoShadows.md(context)
        : NeoShadows.sm(context);

    Widget body = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: r,
        border: dashedBorder
            ? null
            : Border.all(color: borderColor, width: 2.0),
        boxShadow: dashedBorder ? const [] : shadow,
      ),
      child: child,
    );

    if (dashedBorder) {
      body = CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          colour: borderColour ?? AppColors.textTertiary(context),
          radius: radius,
        ),
        child: body,
      );
    }

    if (onTap != null || onLongPress != null) {
      body = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTap: onTap == null
              ? null
              : () {
                  Haptics.light();
                  onTap!();
                },
          onLongPress: onLongPress == null
              ? null
              : () {
                  Haptics.medium();
                  onLongPress!();
                },
          splashColor: AppColors.gold.withOpacity(0.12),
          highlightColor: AppColors.gold.withOpacity(0.06),
          child: body,
        ),
      );
    }

    if (margin != null) {
      body = Padding(padding: margin!, child: body);
    }
    
    return body;
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color colour;
  final double radius;
  _DashedBorderPainter({required this.colour, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rect);
    final dashPaint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashLen = 6.0;
    const gapLen = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = dist + dashLen;
        final extract = metric.extractPath(dist, next.clamp(0, metric.length));
        canvas.drawPath(extract, dashPaint);
        dist = next + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.colour != colour || old.radius != radius;
}
