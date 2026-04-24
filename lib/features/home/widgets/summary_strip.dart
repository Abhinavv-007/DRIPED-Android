import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../core/widgets/glass_card.dart';

class SummaryStrip extends ConsumerWidget {
  const SummaryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final ccy = ref.watch(preferredCurrencyProvider);

    final monthly =
        CurrencyUtil.convert(summary.monthlyTotalINR, 'INR', ccy);
    final yearly =
        CurrencyUtil.convert(summary.yearlyTotalINR, 'INR', ccy);
    final averageActive =
        summary.activeCount == 0 ? 0.0 : monthly / summary.activeCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Column(
        children: [
          _HeroSpendCard(
            monthly: monthly,
            yearly: yearly,
            ccy: ccy,
            activeCount: summary.activeCount,
          ).animate().fadeIn(duration: 260.ms).slideY(
              begin: 0.04,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOutCubic),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SizedBox(
                  height: 124,
                  child: _MiniStatCard(
                    label: 'Projected yearly',
                    icon: LucideIcons.calendar,
                    accent: AppColors.info,
                    child: AnimatedCurrency(
                      value: yearly,
                      currency: ccy,
                      compact: true,
                      color: AppColors.textPrimary(context),
                      style: AppTypography.midNumber.copyWith(fontSize: 24),
                    ),
                    footer: yearly <= 0
                        ? 'Start tracking to see the runway'
                        : 'Recurring annual run rate',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 124,
                  child: _MiniStatCard(
                    label: 'Active subs',
                    icon: LucideIcons.layers,
                    accent: AppColors.success,
                    footer: averageActive <= 0
                        ? 'No spend yet'
                        : 'Avg ${CurrencyUtil.formatAmount(averageActive, code: ccy, compact: true)}/sub',
                    child: AnimatedCount(
                      value: summary.activeCount,
                      style: AppTypography.midNumber.copyWith(
                        fontSize: 24,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: 80.ms, duration: 300.ms)
              .slideY(begin: 0.05, end: 0, duration: 340.ms),
        ],
      ),
    );
  }
}

class _HeroSpendCard extends StatelessWidget {
  final double monthly;
  final double yearly;
  final String ccy;
  final int activeCount;

  const _HeroSpendCard({
    required this.monthly,
    required this.yearly,
    required this.ccy,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    final mutedColor = AppColors.textTertiary(context);
    final runRate = yearly <= 0 ? 0.0 : monthly / yearly;
    final progress = runRate <= 0 ? 0.18 : runRate.clamp(0.12, 0.92);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      emphasised: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withOpacity(0.48)),
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  size: 17,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONTHLY SPEND',
                      style: AppTypography.micro.copyWith(
                        color: subColor,
                        fontSize: 10,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeCount == 0
                          ? 'No active subscriptions yet'
                          : '$activeCount active recurring charges',
                      style: AppTypography.caption.copyWith(color: mutedColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                ),
                child: Text(
                  yearly <= 0
                      ? 'Fresh start'
                      : 'Run rate ${CurrencyUtil.formatAmount(yearly, code: ccy, compact: true)}',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedCurrency(
            value: monthly,
            currency: ccy,
            compact: monthly >= 10000,
            color: textColor,
            style: AppTypography.bigNumber.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 4),
          Text(
            yearly <= 0
                ? 'Add your first live subscription to see your monthly pulse.'
                : 'Projected yearly total ${CurrencyUtil.formatAmount(yearly, code: ccy, compact: true)}',
            style: AppTypography.caption.copyWith(color: subColor),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.cardFill(context, emphasised: true)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.gold, AppColors.goldDeep],
                          ),
                        ),
                      ),
                    ),
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

class _MiniStatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final Widget child;
  final String? footer;

  const _MiniStatCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withOpacity(0.45)),
                  ),
                  child: Icon(icon, size: 14, color: accent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.micro.copyWith(
                      color: AppColors.textSecondary(context),
                      fontSize: 10,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
            const Spacer(),
            if (footer != null)
              Text(
                footer!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
