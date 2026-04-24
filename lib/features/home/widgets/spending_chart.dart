import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/glass_card.dart';

class SpendingChart extends ConsumerWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(last6MonthsSpendProvider);
    final ccy = ref.watch(preferredCurrencyProvider);

    final maxVal = points.isEmpty
        ? 100.0
        : points.map((p) => p.totalInUserCurrency).reduce((a, b) => a > b ? a : b);
    final softMax = (maxVal * 1.25).clamp(100, double.infinity).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('6-month spend',
                  style: AppTypography.cardTitle
                      .copyWith(color: AppColors.textHi)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: softMax,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.inkOverlay,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      tooltipRoundedRadius: 6,
                      getTooltipItem: (group, gIdx, rod, rIdx) {
                        final p = points[gIdx];
                        return BarTooltipItem(
                          '${DateFormat('MMM yyyy').format(p.month)}\n',
                          AppTypography.micro.copyWith(color: AppColors.textMid),
                          children: [
                            TextSpan(
                              text: CurrencyUtil.formatAmount(
                                p.totalInUserCurrency,
                                code: ccy,
                                decimals: 0,
                              ),
                              style: AppTypography.cardTitle.copyWith(
                                  color: AppColors.gold, fontSize: 16),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: softMax / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.hairline,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= points.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(points[i].month),
                              style: AppTypography.micro
                                  .copyWith(color: AppColors.textLow),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: points[i].totalInUserCurrency,
                            width: 18,
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.gold.withOpacity(0.6),
                                AppColors.gold,
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 260.ms, duration: 360.ms).slideY(
        begin: 0.05,
        end: 0,
        duration: 380.ms,
        curve: Curves.easeOutCubic);
  }
}
