import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Driped logomark — a premium liquid drop with inner drip motif.
/// Custom paint, no assets.
class DripedLogo extends StatelessWidget {
  final double size;
  final Color colour;
  const DripedLogo({super.key, this.size = 80, this.colour = AppColors.gold});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DripedLogoPainter(colour, size)),
    );
  }
}

class _DripedLogoPainter extends CustomPainter {
  final Color colour;
  final double size;
  _DripedLogoPainter(this.colour, this.size);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // === Outer drop shape ===
    final dropPath = Path();
    final top = Offset(w * 0.5, h * 0.04);
    dropPath.moveTo(top.dx, top.dy);
    // Left curve
    dropPath.cubicTo(
      w * 0.08, h * 0.38,
      w * 0.12, h * 0.72,
      w * 0.28, h * 0.86,
    );
    // Bottom curve
    dropPath.cubicTo(
      w * 0.36, h * 0.94,
      w * 0.64, h * 0.94,
      w * 0.72, h * 0.86,
    );
    // Right curve
    dropPath.cubicTo(
      w * 0.88, h * 0.72,
      w * 0.92, h * 0.38,
      top.dx, top.dy,
    );
    dropPath.close();

    // Hard offset shadow (brutalist)
    canvas.save();
    canvas.translate(3, 4);
    canvas.drawPath(
      dropPath,
      Paint()..color = AppColors.shadowInk.withOpacity(0.45),
    );
    canvas.restore();

    // Main fill with gradient
    canvas.drawPath(
      dropPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colour, Colors.white, 0.20)!,
            colour,
            Color.lerp(colour, const Color(0xFF8B6914), 0.35)!,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Crisp border
    canvas.drawPath(
      dropPath,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035,
    );

    // === Highlight streak (glass reflection) ===
    final hlPath = Path();
    hlPath.moveTo(w * 0.30, h * 0.22);
    hlPath.quadraticBezierTo(w * 0.22, h * 0.40, w * 0.28, h * 0.56);
    canvas.drawPath(
      hlPath,
      Paint()
        ..color = Colors.white.withOpacity(0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );

    // Small highlight dot
    canvas.drawCircle(
      Offset(w * 0.34, h * 0.24),
      w * 0.03,
      Paint()..color = Colors.white.withOpacity(0.65),
    );

    // === Inner drip line (the "D" notch) ===
    final dPath = Path();
    // Vertical bar of D
    dPath.moveTo(w * 0.42, h * 0.42);
    dPath.lineTo(w * 0.42, h * 0.72);
    // Curve of D
    dPath.moveTo(w * 0.42, h * 0.42);
    dPath.cubicTo(
      w * 0.70, h * 0.42,
      w * 0.70, h * 0.72,
      w * 0.42, h * 0.72,
    );

    canvas.drawPath(
      dPath,
      Paint()
        ..color = AppColors.ink.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // === Subtle inner shadow at top ===
    canvas.drawPath(
      dropPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: const Alignment(0, -0.2),
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.3))
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02,
    );
  }

  @override
  bool shouldRepaint(covariant _DripedLogoPainter old) =>
      old.colour != colour || old.size != size;
}

/// Word mark — "DRIPED" with a gold drop next to it.
class DripedWordmark extends StatelessWidget {
  final double height;
  final Color colour;
  const DripedWordmark({
    super.key,
    this.height = 48,
    this.colour = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DripedLogo(size: height, colour: colour),
        SizedBox(width: height * 0.18),
        Text(
          'DRIPED',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: height * 0.58,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
            color: AppColors.textHi,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
