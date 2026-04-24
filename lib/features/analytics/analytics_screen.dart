import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/billing_cycle.dart';
import '../../core/models/payment_method.dart';
import '../../core/models/subscription.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../payment_methods/widgets/pm_icon.dart';
import '../../core/widgets/service_avatar.dart';

enum _Range { m3, m6, m12 }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _Range _range = _Range.m6;

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(liveSubscriptionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 140),
          children: [
            CustomHeader(
              title: 'Analytics',
              subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
              actions: [
                HeaderAction(icon: LucideIcons.share2, onTap: Haptics.tap),
                HeaderAction(icon: LucideIcons.download, onTap: Haptics.tap),
              ],
            ),
            if (subs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: EmptyState(
                  kind: EmptyStateKind.analytics,
                  title: 'No data yet',
                  subtitle: 'Add subscriptions to see insights',
                ),
              )
            else ...[
              _rangeRow(),
              const SizedBox(height: 4),
              _allDataDropdown(),
              const SizedBox(height: 12),
              const _StatsGrid(),
              const SectionHeader(title: 'SPENDING TREND'),
              _SpendingTrend(range: _range),
              const SectionHeader(title: 'CATEGORY BREAKDOWN'),
              const _CategoryBreakdown(),
              const SectionHeader(title: 'PAYMENT METHOD DISTRIBUTION'),
              const _PaymentMethodDistribution(),
              const SectionHeader(title: 'TOP EXPENSIVE SERVICES'),
              const _TopServices(),
              const SectionHeader(title: 'BILLING CYCLE DISTRIBUTION'),
              const _BillingCycleDist(),
              const SectionHeader(title: 'INSIGHTS & RECOMMENDATIONS'),
              const _Insights(),
              const SectionHeader(title: 'CATEGORIES'),
              const _CategoriesGrid(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rangeRow() {
    final selectedColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.cardFill(context),
          border: Border.all(color: AppColors.cardBorder(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (final r in _Range.values)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Haptics.tap();
                    setState(() => _range = r);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: r == _range
                          ? AppColors.cardFill(context, emphasised: true)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: r == _range
                              ? AppColors.cardBorder(context, strong: true)
                              : Colors.transparent),
                    ),
                    child: Text(
                      _rangeLabel(r),
                      style: AppTypography.caption.copyWith(
                        color: r == _range ? selectedColor : subColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _rangeLabel(_Range r) {
    switch (r) {
      case _Range.m3:
        return '3M';
      case _Range.m6:
        return '6M';
      case _Range.m12:
        return '12M';
    }
  }

  Widget _allDataDropdown() {
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardFill(context),
          border: Border.all(color: AppColors.cardBorder(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text('All data',
                style: AppTypography.body.copyWith(
                    color: textColor, fontWeight: FontWeight.w700)),
            const Spacer(),
            Icon(LucideIcons.chevronDown, size: 16, color: subColor),
          ],
        ),
      ),
    );
  }
}

// ─── stats 2x2 grid ────────────────────────────────────────────────

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    final monthly = CurrencyUtil.convert(summary.monthlyTotalINR, 'INR', ccy);
    final yearly = CurrencyUtil.convert(summary.yearlyTotalINR, 'INR', ccy);
    final avg = summary.activeCount == 0 ? 0.0 : monthly / summary.activeCount;
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    final mutedColor = AppColors.textTertiary(context);

    Widget tile(String label, String value, {String? subLabel}) {
      return GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTypography.micro.copyWith(
                    color: subColor,
                    letterSpacing: 1.0,
                    fontSize: 10)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: AppTypography.bigNumber
                        .copyWith(fontSize: 22, color: textColor)),
                if (subLabel != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(subLabel,
                        style: AppTypography.micro
                            .copyWith(color: mutedColor, fontSize: 10)),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: tile(
                  'SPENT (30D)',
                  CurrencyUtil.formatAmount(monthly,
                      code: ccy, compact: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: tile(
                  'PROJ. YEARLY',
                  CurrencyUtil.formatAmount(yearly,
                      code: ccy, compact: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: tile(
                  'ACTIVE',
                  '${summary.activeCount}',
                  subLabel: 'subs',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: tile(
                  'AVG COST',
                  CurrencyUtil.formatAmount(avg, code: ccy),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── spending trend ────────────────────────────────────────────────

class _SpendingTrend extends ConsumerWidget {
  final _Range range;
  const _SpendingTrend({required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = ref.watch(last6MonthsSpendProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    final data = _windowedMonths(months, range);
    final thisMonth = data.isEmpty ? 0.0 : data.last.totalInUserCurrency;
    final lastMonth = data.length >= 2 ? data[data.length - 2].totalInUserCurrency : 0.0;
    final pct = lastMonth == 0 ? 0.0 : ((thisMonth - lastMonth) / lastMonth) * 100;
    final up = pct >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(10, 14, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                Icon(up ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 14,
                    color: up ? AppColors.danger : AppColors.success),
                const SizedBox(width: 4),
                Text(
                  '${up ? '+' : ''}${pct.toStringAsFixed(1)}%',
                  style: AppTypography.micro.copyWith(
                    color: up ? AppColors.danger : AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: _TrendLineChart(months: data, ccy: ccy),
            ),
          ],
        ),
      ),
    );
  }

  List<MonthlySpendPoint> _windowedMonths(
      List<MonthlySpendPoint> months, _Range r) {
    final n = r == _Range.m3 ? 3 : (r == _Range.m6 ? 6 : 12);
    if (months.length <= n) return months;
    return months.sublist(months.length - n);
  }
}

class _TrendLineChart extends StatelessWidget {
  final List<MonthlySpendPoint> months;
  final String ccy;
  const _TrendLineChart({required this.months, required this.ccy});

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const Center(child: Text('—'));
    }
    final maxY = months
            .map((m) => m.totalInUserCurrency)
            .fold<double>(0, (a, b) => b > a ? b : a) *
        1.25;
    final spots = [
      for (int i = 0; i < months.length; i++)
        FlSpot(i.toDouble(), months[i].totalInUserCurrency),
    ];
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.isDark(context)
                ? AppColors.inkOverlay
                : AppColors.lightCard,
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.toInt();
              return LineTooltipItem(
                '${DateFormat('MMM').format(months[i].month)} · ${CurrencyUtil.formatAmount(s.y, code: ccy, compact: true)}',
                AppTypography.caption.copyWith(
                    color: AppColors.gold, fontWeight: FontWeight.w800),
              );
            }).toList(),
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= months.length) return const SizedBox();
                if (months.length > 6 && i % 2 != 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(DateFormat('MMM').format(months[i].month),
                      style: AppTypography.micro.copyWith(
                          color: AppColors.textTertiary(context), fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: AppColors.gold,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withOpacity(0.28),
                  AppColors.gold.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── category breakdown donut ──────────────────────────────────────

class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slices = ref.watch(categoryBreakdownProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    if (slices.isEmpty) return const SizedBox.shrink();
    final total = slices.fold<double>(0, (a, s) => a + s.totalInUserCurrency);
    final top = slices.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
                      startDegreeOffset: -90,
                      sections: [
                        for (final s in slices)
                          PieChartSectionData(
                            value: s.totalInUserCurrency,
                            color: s.category.colour,
                            radius: 18,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyUtil.formatAmount(total,
                        code: ccy, compact: true),
                    style: AppTypography.cardTitle
                        .copyWith(color: AppColors.gold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  for (final s in top)
                    _LegendRow(
                      colour: s.category.colour,
                      label: s.category.name,
                      pct:
                          total == 0 ? 0 : (s.totalInUserCurrency / total * 100),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _LegendRow extends StatelessWidget {
  final Color colour;
  final String label;
  final double pct;
  const _LegendRow(
      {required this.colour, required this.label, required this.pct});

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption
                    .copyWith(color: subColor, fontSize: 12)),
          ),
          Text('${pct.toStringAsFixed(0)}%',
              style: AppTypography.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              )),
        ],
      ),
    );
  }
}

// ─── payment method distribution ───────────────────────────────────

class _PaymentMethodDistribution extends ConsumerWidget {
  const _PaymentMethodDistribution();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pms = ref.watch(paymentMethodsProvider);
    final subs = ref.watch(liveSubscriptionsProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    if (pms.isEmpty || subs.isEmpty) return const SizedBox.shrink();

    final byPm = <String, double>{};
    for (final s in subs) {
      final key = s.paymentMethodId ?? '_none';
      byPm[key] = (byPm[key] ?? 0) +
          CurrencyUtil.convert(
              s.billingCycle.toMonthly(s.amount), s.currency, ccy);
    }
    final total = byPm.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final rows = <_PmSlice>[];
    for (final pm in pms) {
      final v = byPm[pm.id] ?? 0;
      if (v <= 0) continue;
      rows.add(_PmSlice(pm: pm, amount: v, colour: _pmColour(pm)));
    }
    if ((byPm['_none'] ?? 0) > 0) {
      rows.add(_PmSlice(
          pm: null,
          amount: byPm['_none']!,
          colour: AppColors.textSecondary(context),
          nameOverride: 'Other'));
    }
    rows.sort((a, b) => b.amount.compareTo(a.amount));
    final top = rows.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
                      startDegreeOffset: -90,
                      sections: [
                        for (final r in rows)
                          PieChartSectionData(
                            value: r.amount,
                            color: r.colour,
                            radius: 18,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  Text('Total',
                      style: AppTypography.micro.copyWith(
                          color: AppColors.textSecondary(context),
                          letterSpacing: 1.0)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  for (final r in top)
                    _LegendRow(
                      colour: r.colour,
                      label: r.nameOverride ?? r.pm!.name,
                      pct: r.amount / total * 100,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Color _pmColour(PaymentMethod pm) {
    // Deterministic per-method colour — same brand colour as card chip.
    return pmAccent(pm.type);
  }
}

class _PmSlice {
  final PaymentMethod? pm;
  final double amount;
  final Color colour;
  final String? nameOverride;
  const _PmSlice(
      {required this.pm,
      required this.amount,
      required this.colour,
      this.nameOverride});
}

// ─── top expensive services ────────────────────────────────────────

class _TopServices extends ConsumerWidget {
  const _TopServices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(liveSubscriptionsProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    if (subs.isEmpty) return const SizedBox.shrink();

    final scored = <_ScoredSub>[];
    for (final s in subs) {
      final monthly = CurrencyUtil.convert(
          s.billingCycle.toMonthly(s.amount), s.currency, ccy);
      scored.add(_ScoredSub(sub: s, monthly: monthly));
    }
    scored.sort((a, b) => b.monthly.compareTo(a.monthly));
    final top = scored.take(5).toList();
    final maxV = top.first.monthly;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Column(
          children: [
            for (int i = 0; i < top.length; i++) ...[
              _ServiceRow(
                  sub: top[i].sub,
                  monthly: top[i].monthly,
                  ratio: maxV == 0 ? 0 : top[i].monthly / maxV,
                  ccy: ccy),
              if (i != top.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.divider(context),
                  indent: 42,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoredSub {
  final Subscription sub;
  final double monthly;
  const _ScoredSub({required this.sub, required this.monthly});
}

class _ServiceRow extends StatelessWidget {
  final Subscription sub;
  final double monthly;
  final double ratio;
  final String ccy;
  const _ServiceRow({
    required this.sub,
    required this.monthly,
    required this.ratio,
    required this.ccy,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ServiceAvatar(
                serviceSlug: sub.serviceSlug,
                serviceName: sub.serviceName,
                size: 28,
                glow: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(sub.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle
                        .copyWith(fontSize: 14, color: textColor)),
              ),
              Text(
                '${CurrencyUtil.formatAmount(monthly, code: ccy)}/month',
                style: AppTypography.caption.copyWith(
                    color: textColor, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(children: [
              Container(
                height: 3,
                color: AppColors.cardFill(context, emphasised: true),
              ),
              LayoutBuilder(builder: (_, c) {
                return Container(
                  height: 3,
                  width: c.maxWidth * ratio,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.danger, AppColors.danger.withOpacity(0.5)],
                    ),
                  ),
                );
              }),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── billing cycle distribution ───────────────────────────────────

class _BillingCycleDist extends ConsumerWidget {
  const _BillingCycleDist();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(liveSubscriptionsProvider);
    if (subs.isEmpty) return const SizedBox.shrink();
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);

    int monthlyN = 0;
    int annualN = 0;
    int otherN = 0;
    for (final s in subs) {
      switch (s.billingCycle) {
        case BillingCycle.monthly:
          monthlyN++;
          break;
        case BillingCycle.yearly:
          annualN++;
          break;
        default:
          otherN++;
      }
    }
    final total = monthlyN + annualN + otherN;
    if (total == 0) return const SizedBox.shrink();

    Widget row(String label, int n) {
      final pct = n / total;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Text(label,
                    style: AppTypography.body.copyWith(
                        color: textColor, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$n ${n == 1 ? 'subscription' : 'subscriptions'}',
                    style: AppTypography.caption
                        .copyWith(color: subColor)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(children: [
                Container(
                  height: 4,
                  color: AppColors.cardFill(context, emphasised: true),
                ),
                LayoutBuilder(builder: (_, c) {
                  return Container(
                    height: 4,
                    width: c.maxWidth * pct,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.danger,
                          AppColors.danger.withOpacity(0.4)
                        ],
                      ),
                    ),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: AppTypography.micro.copyWith(
                      color: subColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          children: [
            row('Monthly', monthlyN),
            row('Annual', annualN),
            if (otherN > 0) row('Other', otherN),
          ],
        ),
      ),
    );
  }
}

// ─── insights ─────────────────────────────────────────────────────

class _Insights extends ConsumerWidget {
  const _Insights();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final subs = ref.watch(liveSubscriptionsProvider);
    final slices = ref.watch(categoryBreakdownProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    if (subs.isEmpty) return const SizedBox.shrink();

    final monthly = CurrencyUtil.convert(summary.monthlyTotalINR, 'INR', ccy);
    final avg = summary.activeCount == 0 ? 0 : monthly / summary.activeCount;

    // Pick the priciest sub
    final scored = [...subs];
    scored.sort((a, b) {
      final am = CurrencyUtil.convert(
          a.billingCycle.toMonthly(a.amount), a.currency, ccy);
      final bm = CurrencyUtil.convert(
          b.billingCycle.toMonthly(b.amount), b.currency, ccy);
      return bm.compareTo(am);
    });
    final priciest = scored.first;
    final priciestMonthly = CurrencyUtil.convert(
        priciest.billingCycle.toMonthly(priciest.amount),
        priciest.currency,
        ccy);
    final pricePct =
        monthly == 0 ? 0.0 : (priciestMonthly / monthly * 100);
    final isCostAlert = pricePct >= 15 || priciestMonthly > avg * 2;

    final topCat = slices.isEmpty ? null : slices.first;
    final totalSlices =
        slices.fold<double>(0, (a, s) => a + s.totalInUserCurrency);
    final topCatPct = topCat == null || totalSlices == 0
        ? 0.0
        : topCat.totalInUserCurrency / totalSlices * 100;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          if (isCostAlert)
            _InsightCard(
              accent: AppColors.danger,
              pillText: 'Cost Alert',
              title: priciest.serviceName,
              body:
                  '${priciest.serviceName} costs ${CurrencyUtil.formatAmount(priciestMonthly, code: ccy)}/month (${pricePct.toStringAsFixed(0)}% of total spending). This is more than double your average subscription cost.',
            ),
          if (topCat != null) ...[
            const SizedBox(height: 10),
            _InsightCard(
              accent: AppColors.info,
              pillText: 'Category',
              title: topCat.category.name,
              body:
                  '${topCat.category.name} accounts for ${topCatPct.toStringAsFixed(0)}% of your budget with ${topCat.subCount} services. Consider consolidating services in this category.',
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Color accent;
  final String pillText;
  final String title;
  final String body;
  const _InsightCard({
    required this.accent,
    required this.pillText,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      borderColour: accent.withOpacity(0.45),
      tint: accent.withOpacity(0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              border: Border.all(color: accent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(pillText,
                style: AppTypography.micro.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontSize: 11)),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: AppTypography.body
                  .copyWith(
                    color: AppColors.textPrimary(context),
                    fontSize: 13,
                    height: 1.4,
                  ),
              children: [
                TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── categories grid ───────────────────────────────────────────────

class _CategoriesGrid extends ConsumerWidget {
  const _CategoriesGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slices = ref.watch(categoryBreakdownProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    if (slices.isEmpty) return const SizedBox.shrink();

    final pairs = <List<CategorySlice>>[];
    for (int i = 0; i < slices.length; i += 2) {
      pairs.add(slices.sublist(i, (i + 2).clamp(0, slices.length)));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          for (int p = 0; p < pairs.length; p++) ...[
            if (p > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CatCell(
                    slice: pairs[p][0],
                    ccy: ccy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: pairs[p].length > 1
                      ? _CatCell(slice: pairs[p][1], ccy: ccy)
                      : const SizedBox(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CatCell extends StatelessWidget {
  final CategorySlice slice;
  final String ccy;
  const _CatCell({required this.slice, required this.ccy});

  @override
  Widget build(BuildContext context) {
    final subColor = AppColors.textSecondary(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: slice.category.colour,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: slice.category.colour.withOpacity(0.6),
                    blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slice.category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.micro.copyWith(
                        color: subColor, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  CurrencyUtil.formatAmount(slice.totalInUserCurrency,
                      code: ccy),
                  style: AppTypography.cardTitle
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
