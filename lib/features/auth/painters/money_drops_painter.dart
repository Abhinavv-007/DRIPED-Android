import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Stylised crushed banknote leaking red drops.
/// The note subtly twists over time while drops fall from the pinch point.
class MoneyDropsPainter extends CustomPainter {
  final double t;

  MoneyDropsPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height * 0.38);
    final pulse = math.sin(t * math.pi * 2);
    final squeeze = 0.82 + pulse * 0.08;
    final tilt = -0.18 + pulse * 0.03;

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(tilt);

    final noteRect = Rect.fromCenter(
      center: Offset.zero,
      width: size.width * 0.66,
      height: size.height * 0.28,
    );

    final notePath = Path()
      ..moveTo(noteRect.left, noteRect.top + 12)
      ..quadraticBezierTo(
        noteRect.left + noteRect.width * 0.22,
        noteRect.top - 18,
        noteRect.center.dx - 12,
        noteRect.top + 8,
      )
      ..quadraticBezierTo(
        noteRect.center.dx,
        noteRect.top + 22 * squeeze,
        noteRect.center.dx + 12,
        noteRect.top + 8,
      )
      ..quadraticBezierTo(
        noteRect.right - noteRect.width * 0.22,
        noteRect.top - 18,
        noteRect.right,
        noteRect.top + 10,
      )
      ..lineTo(noteRect.right, noteRect.bottom - 12)
      ..quadraticBezierTo(
        noteRect.right - noteRect.width * 0.22,
        noteRect.bottom + 18,
        noteRect.center.dx + 14,
        noteRect.bottom - 6,
      )
      ..quadraticBezierTo(
        noteRect.center.dx,
        noteRect.bottom - 18 * squeeze,
        noteRect.center.dx - 14,
        noteRect.bottom - 6,
      )
      ..quadraticBezierTo(
        noteRect.left + noteRect.width * 0.2,
        noteRect.bottom + 18,
        noteRect.left,
        noteRect.bottom - 14,
      )
      ..close();

    final noteFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFFA7D88C),
          Color(0xFF7FBE74),
          Color(0xFF6AA96B),
        ],
      ).createShader(noteRect);
    final noteStroke = Paint()
      ..color = const Color(0xFF335C35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawShadow(notePath, AppColors.shadowInk, 18, false);
    canvas.drawPath(notePath, noteFill);
    canvas.drawPath(notePath, noteStroke);

    final inner = noteRect.deflate(18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(18)),
      Paint()
        ..color = const Color(0x26FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final portrait = Rect.fromCenter(
      center: Offset(0, 0),
      width: inner.width * 0.28,
      height: inner.height * 0.52,
    );
    canvas.drawOval(
      portrait,
      Paint()
        ..color = const Color(0x30526E4C)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      portrait,
      Paint()
        ..color = const Color(0xFF335C35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final detail = Paint()
      ..color = const Color(0xFF335C35).withOpacity(0.65)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final dy = inner.top + 16 + i * 18;
      canvas.drawLine(
        Offset(inner.left + 16, dy),
        Offset(inner.left + inner.width * 0.28, dy),
        detail,
      );
      canvas.drawLine(
        Offset(inner.right - inner.width * 0.28, dy),
        Offset(inner.right - 16, dy),
        detail,
      );
    }

    final pinchPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-12, -inner.height * 0.44),
      Offset(12, inner.height * 0.44),
      pinchPaint,
    );
    canvas.drawLine(
      Offset(12, -inner.height * 0.44),
      Offset(-12, inner.height * 0.44),
      pinchPaint,
    );

    canvas.restore();

    final dripOrigin = Offset(
      centre.dx + math.sin(t * math.pi * 2) * 6,
      centre.dy + size.height * 0.13,
    );
    _drawCrimsonDrops(canvas, size, dripOrigin);
  }

  void _drawCrimsonDrops(Canvas canvas, Size size, Offset origin) {
    final dropColor = const Color(0xFFE33939);
    final glow = const Color(0x55FF6B6B);
    final streakPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final drops = <({double dx, double start, double speed, double size})>[
      (dx: -24, start: 0.08, speed: 0.78, size: 10),
      (dx: -4, start: 0.22, speed: 0.95, size: 12),
      (dx: 18, start: 0.34, speed: 0.88, size: 9),
      (dx: 36, start: 0.52, speed: 0.72, size: 7),
    ];

    for (final drop in drops) {
      final progress = (t + drop.start) % 1.0;
      final y = origin.dy + progress * (size.height * 0.42);
      final x = origin.dx + drop.dx + math.sin(progress * math.pi * 2) * 4;
      final radius = drop.size * (0.82 + progress * 0.18);

      streakPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [glow.withOpacity(0), glow, dropColor.withOpacity(0.35)],
      ).createShader(Rect.fromLTWH(x - 2, origin.dy - 8, 4, y - origin.dy + 10));

      canvas.drawLine(
        Offset(x, origin.dy - 6),
        Offset(x, y - radius * 0.8),
        streakPaint,
      );

      final path = Path()
        ..moveTo(x, y - radius * 1.35)
        ..quadraticBezierTo(x - radius, y - radius * 0.1, x, y + radius)
        ..quadraticBezierTo(x + radius, y - radius * 0.1, x, y - radius * 1.35);
      canvas.drawPath(path, Paint()..color = dropColor);
      canvas.drawCircle(
        Offset(x - radius * 0.28, y - radius * 0.35),
        radius * 0.2,
        Paint()..color = Colors.white.withOpacity(0.24),
      );
    }

    final puddleY = size.height * 0.86;
    final puddle = Paint()..color = const Color(0x44E33939);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(origin.dx + 10, puddleY),
        width: size.width * 0.22,
        height: 16,
      ),
      puddle,
    );
    for (final splash in [(-30.0, 0.0, 5.0), (12.0, -6.0, 3.0), (38.0, 2.0, 4.0)]) {
      canvas.drawCircle(
        Offset(origin.dx + splash.$1, puddleY + splash.$2),
        splash.$3,
        Paint()..color = const Color(0x88E33939),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MoneyDropsPainter old) => old.t != t;
}
