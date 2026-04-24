import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/glass_card.dart';

/// Side-by-side Total Monthly + Active Subs cards.
class StatsPair extends ConsumerWidget {
  const StatsPair({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final months = ref.watch(last6MonthsSpendProvider);
    final ccy = ref.watch(preferredCurrencyProvider);

    final monthly = CurrencyUtil.convert(summary.monthlyTotalINR, 'INR', ccy);
    final yearly = CurrencyUtil.convert(summary.yearlyTotalINR, 'INR', ccy);

    final thisMonth = months.isEmpty ? monthly : months.last.totalInUserCurrency;
    final lastMonth =
        months.length >= 2 ? months[months.length - 2].totalInUserCurrency : 0.0;
    final delta = lastMonth == 0 ? 0.0 : ((thisMonth - lastMonth) / lastMonth) * 100;
    final avgPerSub = summary.activeCount == 0
        ? 0
        : monthly / summary.activeCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(LucideIcons.dollarSign,
                          size: 13, color: AppColors.gold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Total Monthly',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.micro.copyWith(
                              color: AppColors.textMid,
                              fontSize: 11,
                              letterSpacing: 0.5)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    CurrencyUtil.formatAmount(monthly, code: ccy, compact: true),
                    style: AppTypography.bigNumber.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(
                      delta >= 0
                          ? LucideIcons.arrowUp
                          : LucideIcons.arrowDown,
                      size: 11,
                      color: delta >= 0 ? AppColors.danger : AppColors.success,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${delta.abs().toStringAsFixed(0)}%',
                      style: AppTypography.micro.copyWith(
                        color: delta >= 0 ? AppColors.danger : AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Yearly: ${CurrencyUtil.formatAmount(yearly, code: ccy, compact: true)}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.micro.copyWith(
                            color: AppColors.textLow, fontSize: 10),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(LucideIcons.layers,
                          size: 13, color: AppColors.info),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Active Subs',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.micro.copyWith(
                              color: AppColors.textMid,
                              fontSize: 11,
                              letterSpacing: 0.5)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    '${summary.activeCount}',
                    style: AppTypography.bigNumber.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '~${CurrencyUtil.formatAmount(avgPerSub.toDouble(), code: ccy)}/sub',
                    style: AppTypography.micro
                        .copyWith(color: AppColors.textLow, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
