import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/glass_card.dart';

/// Monthly spend vs category-budget-sum card.
/// Shows progress bar + days remaining in current month.
class MonthlyBudgetCard extends ConsumerWidget {
  const MonthlyBudgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final cats = ref.watch(categoriesProvider);
    final ccy = ref.watch(preferredCurrencyProvider);

    final spent = CurrencyUtil.convert(summary.monthlyTotalINR, 'INR', ccy);
    final budget = _computeBudget(cats, ccy, spent);
    final pct = budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = lastDay - now.day;

    final barColour = pct > 0.9
        ? AppColors.danger
        : pct > 0.65
            ? AppColors.warning
            : AppColors.gold;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('MONTHLY BUDGET',
                    style: AppTypography.micro.copyWith(
                        color: AppColors.textMid,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('$daysLeft days left',
                    style: AppTypography.micro.copyWith(
                        color: AppColors.gold,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtil.formatAmount(spent, code: ccy),
                  style: AppTypography.bigNumber.copyWith(fontSize: 32),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    ' / ${CurrencyUtil.formatAmount(budget, code: ccy)}',
                    style: AppTypography.body.copyWith(
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  LayoutBuilder(builder: (_, c) {
                    return Container(
                      height: 8,
                      width: (c.maxWidth * pct).clamp(0, c.maxWidth),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [barColour, barColour.withOpacity(0.6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: barColour.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 0)),
                        ],
                      ),
                    ).animate().scaleX(
                        alignment: Alignment.centerLeft,
                        begin: 0,
                        end: 1,
                        duration: 600.ms,
                        curve: Curves.easeOutCubic);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${(pct * 100).toStringAsFixed(0)}% used',
                  style: AppTypography.micro
                      .copyWith(color: AppColors.textMid, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  double _computeBudget(List cats, String ccy, double spent) {
    double sum = 0;
    for (final c in cats) {
      if (c.budgetLimit != null) {
        sum += CurrencyUtil.convert(c.budgetLimit as double, 'INR', ccy);
      }
    }
    if (sum == 0) {
      // Fallback: round spent up to next nice target ~ 2x spend.
      final target = spent * 2;
      return target < 100 ? 100 : _roundUp(target);
    }
    return sum;
  }

  double _roundUp(double v) {
    if (v <= 500) return 500;
    if (v <= 1000) return 1000;
    if (v <= 5000) return ((v / 1000).ceil() * 1000).toDouble();
    return ((v / 5000).ceil() * 5000).toDouble();
  }
}
