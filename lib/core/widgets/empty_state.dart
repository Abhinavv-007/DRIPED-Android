import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Illustrated empty state. Never a blank screen.
/// Uses a CustomPainter to render a stylised icon related to the
/// semantic of what is empty (subs / methods / analytics / etc).
class EmptyState extends StatelessWidget {
  final EmptyStateKind kind;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.kind,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 180,
                child: CustomPaint(painter: _EmptyPainter(kind, isDark: isDark)),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .slideY(
                      begin: 0.015,
                      end: -0.015,
                      duration: 3.seconds,
                      curve: Curves.easeInOutSine)
                  .then()
                  .slideY(
                      begin: -0.015,
                      end: 0.015,
                      duration: 3.seconds,
                      curve: Curves.easeInOutSine),
              const SizedBox(height: 20),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle
                      .copyWith(color: AppColors.textPrimary(context))),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary(context))),
              if (action != null) ...[
                const SizedBox(height: 22),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum EmptyStateKind {
  subscriptions,
  paymentMethods,
  analytics,
  searchNoResult,
  categoryEmpty,
  history,
  trialsClear,
}

class _EmptyPainter extends CustomPainter {
  final EmptyStateKind kind;
  final bool isDark;
  _EmptyPainter(this.kind, {required this.isDark});

  Color get _surface => isDark ? AppColors.glassFill : AppColors.lightCard;
  Color get _muted => isDark ? AppColors.textLow : AppColors.lightTextLow;
  Color get _shadow =>
      isDark ? AppColors.shadowInk : const Color(0x33000000);
  Color get _chip =>
      isDark ? AppColors.ink.withOpacity(0.6) : AppColors.lightText.withOpacity(0.18);

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    switch (kind) {
      case EmptyStateKind.subscriptions:
        _drawReceipt(canvas, size, centre);
        break;
      case EmptyStateKind.paymentMethods:
        _drawCard(canvas, size, centre);
        break;
      case EmptyStateKind.analytics:
        _drawBars(canvas, size, centre);
        break;
      case EmptyStateKind.searchNoResult:
        _drawSearch(canvas, size, centre);
        break;
      case EmptyStateKind.categoryEmpty:
        _drawTag(canvas, size, centre);
        break;
      case EmptyStateKind.history:
        _drawClock(canvas, size, centre);
        break;
      case EmptyStateKind.trialsClear:
        _drawCheck(canvas, size, centre);
        break;
    }
  }

  // ─── receipt (subscriptions empty) ───
  void _drawReceipt(Canvas c, Size s, Offset centre) {
    final r = Rect.fromCenter(center: centre, width: 120, height: 150);
    final fill = Paint()
      ..color = _surface
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    path.moveTo(r.left, r.top);
    path.lineTo(r.right, r.top);
    path.lineTo(r.right, r.bottom - 12);
    // zig-zag bottom
    for (double x = r.right; x > r.left; x -= 12) {
      path.lineTo(x - 6, r.bottom);
      path.lineTo(x - 12, r.bottom - 12);
    }
    path.lineTo(r.left, r.top);
    c.drawPath(path, fill);
    c.drawPath(path, stroke);

    // lines
    final lp = Paint()
      ..color = _muted
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final y = r.top + 30 + i * 18.0;
      c.drawLine(Offset(r.left + 14, y),
          Offset(r.right - 14 - i * 18, y), lp);
    }

    // big gold dot — representing the drip
    c.drawCircle(
        Offset(r.right - 20, r.top + 22),
        6,
        Paint()..color = AppColors.gold);
  }

  // ─── credit card ───
  void _drawCard(Canvas c, Size s, Offset centre) {
    final r = Rect.fromCenter(center: centre, width: 170, height: 110);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.gold, AppColors.goldDeep],
      ).createShader(r);
    c.drawRRect(rr, fill);
    c.drawRRect(
        rr,
        Paint()
          ..color = _shadow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // chip
    final chip = Rect.fromLTWH(r.left + 16, r.top + 32, 28, 22);
    c.drawRRect(
        RRect.fromRectAndRadius(chip, const Radius.circular(4)),
        Paint()..color = _chip);

    // numbers
    final np = Paint()
      ..color = AppColors.ink
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    for (int i = 0; i < 4; i++) {
      final y = r.top + 72.0;
      final x = r.left + 16.0 + i * 36;
      c.drawLine(Offset(x, y), Offset(x + 22, y), np);
    }
  }

  // ─── bars (analytics) ───
  void _drawBars(Canvas c, Size s, Offset centre) {
    const barCount = 5;
    const barW = 22.0;
    const gap = 8.0;
    final totalW = barCount * barW + (barCount - 1) * gap;
    final base = Offset(centre.dx - totalW / 2, centre.dy + 60);
    final heights = [48.0, 84.0, 62.0, 110.0, 72.0];
    for (int i = 0; i < barCount; i++) {
      final x = base.dx + i * (barW + gap);
      final rect = Rect.fromLTWH(x, base.dy - heights[i], barW, heights[i]);
      c.drawRect(rect, Paint()..color = AppColors.gold);
      c.drawRect(
          rect,
          Paint()
            ..color = AppColors.shadowInk
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  // ─── search ───
  void _drawSearch(Canvas c, Size s, Offset centre) {
    c.drawCircle(
        centre.translate(-10, -10),
        44,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    c.drawLine(
        centre.translate(22, 22),
        centre.translate(52, 52),
        Paint()
          ..color = AppColors.gold
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
  }

  // ─── tag ───
  void _drawTag(Canvas c, Size s, Offset centre) {
    final path = Path();
    path.moveTo(centre.dx - 50, centre.dy - 40);
    path.lineTo(centre.dx + 20, centre.dy - 40);
    path.lineTo(centre.dx + 60, centre.dy);
    path.lineTo(centre.dx + 20, centre.dy + 40);
    path.lineTo(centre.dx - 50, centre.dy + 40);
    path.close();
    c.drawPath(path, Paint()..color = _surface);
    c.drawPath(
        path,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    c.drawCircle(Offset(centre.dx - 28, centre.dy), 6,
        Paint()..color = AppColors.gold);
  }

  // ─── clock ───
  void _drawClock(Canvas c, Size s, Offset centre) {
    final p = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    c.drawCircle(centre, 54, p);
    final hand = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(centre, centre.translate(0, -36), hand);
    c.drawLine(centre,
        centre.translate(30 * math.cos(-math.pi / 6),
            30 * math.sin(-math.pi / 6)),
        hand);
  }

  // ─── check ───
  void _drawCheck(Canvas c, Size s, Offset centre) {
    c.drawCircle(centre, 62,
        Paint()..color = AppColors.success.withOpacity(0.15));
    final path = Path()
      ..moveTo(centre.dx - 22, centre.dy + 2)
      ..lineTo(centre.dx - 6, centre.dy + 22)
      ..lineTo(centre.dx + 28, centre.dy - 18);
    c.drawPath(
        path,
        Paint()
          ..color = AppColors.success
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _EmptyPainter old) =>
      old.kind != kind || old.isDark != isDark;
}
