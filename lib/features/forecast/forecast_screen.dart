import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neo_stat_tile.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(preferredCurrencyProvider);
    final forecastAsync = ref.watch(forecastProvider(12));
    final calendarAsync = ref.watch(calendarProvider(90));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CustomHeader(
                leading: HeaderAvatar(
                  imageUrl: null,
                  fallbackInitial: '\u2192',
                  onTap: () => context.go('/home'),
                ),
                title: 'Forecast',
                subtitle: 'Next 12 months at your current pace',
              ).animate().fadeIn(duration: 400.ms),
            ),
            forecastAsync.when(
              data: (months) => _forecastSlivers(context, months, currency),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: _errorBox(context, e.toString()),
              ),
            ),
            calendarAsync.when(
              data: (charges) =>
                  _calendarSliver(context, charges, currency),
              loading: () => const SliverToBoxAdapter(child: SizedBox(height: 40)),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox(height: 0)),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns 3 KPI tiles + a bar chart as a SliverMultiBoxAdaptor.
  Widget _forecastSlivers(
    BuildContext context,
    List<Map<String, dynamic>> months,
    String currency,
  ) {
    final annual = months.fold<double>(
        0, (s, m) => s + ((m['total'] as num?)?.toDouble() ?? 0));
    final peak = months.isEmpty
        ? null
        : months.reduce((a, b) =>
            ((a['total'] as num?)?.toDouble() ?? 0) >=
                    ((b['total'] as num?)?.toDouble() ?? 0)
                ? a
                : b);

    final maxY = months.fold<double>(
        1, (m, r) => ((r['total'] as num?)?.toDouble() ?? 0) > m
            ? (r['total'] as num).toDouble()
            : m);

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: [
              NeoStatTile(
                label: 'Annual',
                value: CurrencyUtil.formatAmount(annual,
                    code: currency, compact: true),
                icon: LucideIcons.trendingUp,
                tone: NeoTileTone.lemon,
              ),
              NeoStatTile(
                label: 'Peak month',
                value: peak == null
                    ? '\u2014'
                    : CurrencyUtil.formatAmount(
                        (peak['total'] as num).toDouble(),
                        code: currency,
                        compact: true,
                      ),
                delta: peak == null ? null : _monthLabel(peak['month'] as String),
                icon: LucideIcons.sparkles,
                tone: NeoTileTone.coral,
              ),
              NeoStatTile(
                label: 'Months',
                value: '${months.length}',
                icon: LucideIcons.calendarDays,
                tone: NeoTileTone.sky,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GlassCard(
            emphasised: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT 12 MONTHS',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary(context),
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceBetween,
                      maxY: maxY * 1.15,
                      barGroups: List.generate(months.length, (i) {
                        final val = (months[i]['total'] as num?)?.toDouble() ?? 0;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: val,
                              width: 14,
                              color: i.isEven
                                  ? AppColors.gold
                                  : AppColors.lilac(context),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4)),
                              borderSide: BorderSide(
                                color: AppColors.textPrimary(context),
                                width: 1.5,
                              ),
                            ),
                          ],
                        );
                      }),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.divider(context),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= months.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _monthLabel(months[i]['month'] as String),
                                  style: AppTypography.micro.copyWith(
                                    color: AppColors.textTertiary(context),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _calendarSliver(
    BuildContext context,
    List<Map<String, dynamic>> charges,
    String currency,
  ) {
    // Bucket charges by date
    final byDay = <String, double>{};
    for (final c in charges) {
      final d = c['date'] as String? ?? '';
      if (d.isEmpty) continue;
      byDay[d] =
          (byDay[d] ?? 0) + ((c['amount'] as num?)?.toDouble() ?? 0);
    }
    final today = DateTime.now();
    final days = List.generate(90, (i) {
      final d = DateTime(today.year, today.month, today.day + i);
      final iso = d.toIso8601String().substring(0, 10);
      return MapEntry(iso, byDay[iso] ?? 0);
    });
    final max = days.fold<double>(1, (m, d) => d.value > m ? d.value : m);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RENEWAL CALENDAR \u2022 90 DAYS',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary(context),
                    letterSpacing: 2,
                  )),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const cellMin = 20.0;
                  const spacing = 4.0;
                  final cols = ((constraints.maxWidth + spacing) /
                          (cellMin + spacing))
                      .floor()
                      .clamp(14, 20);
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: days.map((d) {
                      final v = d.value;
                      final intensity = v / max;
                      final bg = v == 0
                          ? AppColors.cardFill(context).withOpacity(0.45)
                          : Color.lerp(
                              AppColors.cardFill(context),
                              AppColors.gold,
                              0.15 + intensity * 0.75,
                            )!;
                      final w = (constraints.maxWidth - (cols - 1) * spacing) /
                          cols;
                      return Tooltip(
                        message: v == 0
                            ? d.key
                            : '${d.key} \u2022 ${CurrencyUtil.formatAmount(v, code: currency, compact: true)}',
                        child: Container(
                          width: w,
                          height: w,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.textPrimary(context),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text('Brighter = heavier charge day.',
                  style: AppTypography.micro
                      .copyWith(color: AppColors.textTertiary(context))),
            ],
          ),
        ),
      ),
    );
  }

  static String _monthLabel(String iso) {
    // "YYYY-MM" \u2192 "MMM 'YY"
    final parts = iso.split('-');
    if (parts.length < 2) return iso;
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 1;
    if (month < 1 || month > 12) return iso;
    return "${_monthNames[month - 1]} '${year.toString().substring(2)}";
  }

  Widget _errorBox(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Couldn\u2019t load forecast \u2014 $message',
        style: AppTypography.caption.copyWith(color: AppColors.danger),
      ),
    );
  }
}
