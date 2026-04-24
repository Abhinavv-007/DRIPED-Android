import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Premium mini-dashboard illustration for onboarding slide 3.
/// Shows a phone-like frame with spend cards, a mini bar chart,
/// and action buttons — all animated in with stagger.
class DashboardSlidePainter extends CustomPainter {
  final double t;
  DashboardSlidePainter({required this.t});

  double _ease(double x) => Curves.easeOutCubic.transform(x.clamp(0, 1));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // --- Phone frame ---
    final frameW = w * 0.68;
    final frameH = h * 0.88;
    final frameL = cx - frameW / 2;
    final frameT = h * 0.06;
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(frameL, frameT, frameW, frameH),
      const Radius.circular(20),
    );

    // Phone shadow
    canvas.drawRRect(
      frameRect.shift(const Offset(4, 6)),
      Paint()..color = AppColors.shadowInk.withOpacity(0.35),
    );

    // Phone body
    canvas.drawRRect(
      frameRect,
      Paint()..color = AppColors.ink,
    );
    canvas.drawRRect(
      frameRect,
      Paint()
        ..color = AppColors.glassBorderHi
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Notch
    final notchW = frameW * 0.28;
    final notchH = 6.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - notchW / 2, frameT + 8, notchW, notchH),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.glassFillHi,
    );

    // --- Content area ---
    final contentL = frameL + 14;
    final contentR = frameL + frameW - 14;
    final contentW = contentR - contentL;
    var cursorY = frameT + 28.0;

    // Stagger phases
    final p1 = _ease(t * 1.6);
    final p2 = _ease(t * 1.6 - 0.15);
    final p3 = _ease(t * 1.6 - 0.3);
    final p4 = _ease(t * 1.6 - 0.45);
    final p5 = _ease(t * 1.6 - 0.6);

    // --- Hero spend card (gold accent) ---
    final heroH = frameH * 0.18;
    final heroY = cursorY + (1 - p1) * 30;
    final heroRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(contentL, heroY, contentW, heroH),
      const Radius.circular(12),
    );
    canvas.drawRRect(heroRect, Paint()..color = AppColors.gold.withOpacity(0.12 * p1));
    canvas.drawRRect(
      heroRect,
      Paint()
        ..color = AppColors.gold.withOpacity(0.5 * p1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Label line
    _line(canvas, contentL + 12, heroY + 14, contentW * 0.3,
        AppColors.textLow.withOpacity(0.7 * p1));
    // Big number
    _line(canvas, contentL + 12, heroY + 30, contentW * 0.5,
        AppColors.gold.withOpacity(0.85 * p1),
        thickness: 5);
    // Sub text
    _line(canvas, contentL + 12, heroY + heroH - 16, contentW * 0.4,
        AppColors.textLow.withOpacity(0.5 * p1));
    // Progress bar
    final barY = heroY + heroH - 8;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(contentL + 12, barY, contentW - 24, 4),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, Paint()..color = AppColors.textGhost.withOpacity(0.4 * p1));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(contentL + 12, barY, (contentW - 24) * 0.65 * p1, 4),
        const Radius.circular(2),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.gold.withOpacity(p1),
            AppColors.goldDeep.withOpacity(p1),
          ],
        ).createShader(Rect.fromLTWH(contentL + 12, barY, contentW - 24, 4)),
    );

    cursorY += heroH + 12;

    // --- Two stat cards side by side ---
    final statW = (contentW - 8) / 2;
    final statH = frameH * 0.12;

    // Left stat
    final statLY = cursorY + (1 - p2) * 40;
    _statCard(canvas, contentL, statLY, statW, statH, p2,
        accentColor: AppColors.info);

    // Right stat
    final statRY = cursorY + (1 - p2) * 50;
    _statCard(canvas, contentL + statW + 8, statRY, statW, statH, p2,
        accentColor: AppColors.success);

    cursorY += statH + 12;

    // --- Mini bar chart ---
    final chartH = frameH * 0.2;
    final chartY = cursorY + (1 - p3) * 50;
    final chartRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(contentL, chartY, contentW, chartH),
      const Radius.circular(12),
    );
    canvas.drawRRect(chartRect, Paint()..color = AppColors.glassFill.withOpacity(p3));
    canvas.drawRRect(
      chartRect,
      Paint()
        ..color = AppColors.glassBorder.withOpacity(p3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Chart bars
    const barCount = 6;
    final barSpacing = (contentW - 24) / barCount;
    final heights = [0.6, 0.82, 0.45, 0.95, 0.7, 0.55];
    for (int i = 0; i < barCount; i++) {
      final bx = contentL + 12 + i * barSpacing + barSpacing * 0.2;
      final bw = barSpacing * 0.5;
      final maxBH = chartH - 30;
      final bh = maxBH * heights[i] * _ease(p3 * 1.3 - i * 0.05);
      final by = chartY + chartH - 12 - bh;
      final isHighest = i == 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, bw, bh),
          const Radius.circular(3),
        ),
        Paint()
          ..color = isHighest
              ? AppColors.gold.withOpacity(0.9 * p3)
              : AppColors.glassFillHi.withOpacity(p3),
      );
    }
    // Chart label
    _line(canvas, contentL + 12, chartY + 12, contentW * 0.2,
        AppColors.textLow.withOpacity(0.6 * p3));

    cursorY += chartH + 12;

    // --- Subscription rows ---
    for (int i = 0; i < 3; i++) {
      final rowP = (i == 0) ? p4 : (i == 1) ? p5 : _ease(t * 1.6 - 0.75);
      final rowY = cursorY + (1 - rowP) * 30 + i * (frameH * 0.065 + 6);
      final rowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(contentL, rowY, contentW, frameH * 0.065),
        const Radius.circular(8),
      );
      canvas.drawRRect(
          rowRect, Paint()..color = AppColors.glassFill.withOpacity(0.8 * rowP));
      // Avatar circle
      final avatarR = frameH * 0.02;
      final colors = [AppColors.gold, AppColors.info, AppColors.success];
      canvas.drawCircle(
        Offset(contentL + 12 + avatarR, rowY + frameH * 0.065 / 2),
        avatarR,
        Paint()..color = colors[i].withOpacity(0.7 * rowP),
      );
      // Text lines
      _line(canvas, contentL + 12 + avatarR * 2 + 8, rowY + frameH * 0.065 / 2 - 4,
          contentW * 0.3, AppColors.textLow.withOpacity(0.6 * rowP));
      _line(canvas, contentL + 12 + avatarR * 2 + 8, rowY + frameH * 0.065 / 2 + 6,
          contentW * 0.15, AppColors.textGhost.withOpacity(0.5 * rowP));
      // Amount
      _line(canvas, contentR - contentW * 0.18, rowY + frameH * 0.065 / 2 - 2,
          contentW * 0.13, AppColors.textMid.withOpacity(0.6 * rowP),
          thickness: 3);
    }
  }

  void _statCard(Canvas canvas, double x, double y, double w, double h,
      double progress,
      {required Color accentColor}) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, Paint()..color = AppColors.glassFill.withOpacity(progress));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppColors.glassBorder.withOpacity(progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Accent dot
    canvas.drawCircle(
      Offset(x + 14, y + 14),
      4,
      Paint()..color = accentColor.withOpacity(0.8 * progress),
    );
    // Label
    _line(canvas, x + 24, y + 12, w * 0.4,
        AppColors.textLow.withOpacity(0.6 * progress));
    // Number
    _line(canvas, x + 14, y + h - 16, w * 0.5,
        AppColors.textMid.withOpacity(0.7 * progress),
        thickness: 4);
  }

  void _line(Canvas canvas, double x, double y, double length, Color color,
      {double thickness = 3}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, length, thickness),
        Radius.circular(thickness / 2),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant DashboardSlidePainter old) => old.t != t;
}
