import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// An envelope with a scanning beam that sweeps across.
/// [t] in [0,1).
class ScanBeamPainter extends CustomPainter {
  final double t;
  ScanBeamPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final env = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.65,
      height: size.width * 0.45,
    );

    // envelope body
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.inkOverlay, AppColors.inkCard],
      ).createShader(env);
    canvas.drawRect(env, fill);
    canvas.drawRect(
        env,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    // flap
    final flap = Path()
      ..moveTo(env.left, env.top)
      ..lineTo(env.center.dx, env.top + env.height * 0.55)
      ..lineTo(env.right, env.top);
    canvas.drawPath(
        flap,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    // three "email rows" inside envelope
    final rowP = Paint()
      ..color = AppColors.textLow.withOpacity(0.7)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    for (int i = 0; i < 3; i++) {
      final y = env.top + env.height * (0.72 + i * 0.08);
      canvas.drawLine(
          Offset(env.left + 16, y),
          Offset(env.right - 16 - i * 20, y),
          rowP);
    }

    // scanning beam — vertical gold line with glow
    final beamX = env.left + env.width * t;
    final beamRect =
        Rect.fromLTWH(beamX - 14, env.top - 18, 28, env.height + 36);
    final beamFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          AppColors.gold.withOpacity(0.85),
          Colors.transparent,
        ],
      ).createShader(beamRect);
    canvas.drawRect(beamRect, beamFill);
    canvas.drawLine(Offset(beamX, env.top - 18),
        Offset(beamX, env.bottom + 18),
        Paint()
          ..color = AppColors.gold
          ..strokeWidth = 2);

    // glow halo
    canvas.drawCircle(
        Offset(beamX, env.center.dy),
        26,
        Paint()
          ..color = AppColors.gold.withOpacity(0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
  }

  @override
  bool shouldRepaint(covariant ScanBeamPainter old) => old.t != t;
}
