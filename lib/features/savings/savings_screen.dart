import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neo_stat_tile.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  final _selected = <String>{};
  Map<String, dynamic>? _whatIf;
  bool _simulating = false;

  Future<void> _refresh() async {
    Haptics.medium();
    ref.invalidate(savingsInsightsProvider);
    await ref.read(savingsInsightsProvider.future);
  }

  Future<void> _runSim() async {
    if (_selected.isEmpty) return;
    setState(() => _simulating = true);
    try {
      final res = await ref
          .read(insightsRepoProvider)
          .whatIf(_selected.toList());
      setState(() => _whatIf = res.data);
    } finally {
      setState(() => _simulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(savingsInsightsProvider);
    final currency = ref.watch(preferredCurrencyProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.gold,
          backgroundColor: AppColors.cardFill(context),
          onRefresh: _refresh,
          child: async.when(
            data: (data) => _body(data, currency),
            loading: () => _skeleton(),
            error: (e, _) => _error(e.toString()),
          ),
        ),
      ),
    );
  }

  Widget _body(Map<String, dynamic> data, String currency) {
    final totals = Map<String, dynamic>.from(data['totals'] ?? {});
    final candidates = (data['cancel_candidates'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final ghosts = (data['ghosts'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final annualHints = (data['annual_hints'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final selectedSaving = candidates
        .where((c) => _selected.contains(c['subscription_id']))
        .fold<double>(
            0, (s, c) => s + ((c['yearly_saving'] as num?)?.toDouble() ?? 0));

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: CustomHeader(
            leading: HeaderAvatar(
              imageUrl: null,
              fallbackInitial: '\$',
              onTap: () => context.go('/home'),
            ),
            title: 'Stop the Drip',
            subtitle: 'Cuts we spotted for you',
          ).animate().fadeIn(duration: 400.ms),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                NeoStatTile(
                  label: 'Active subs',
                  value: '${totals['active_count'] ?? 0}',
                  icon: LucideIcons.layers,
                  tone: NeoTileTone.sky,
                ),
                NeoStatTile(
                  label: 'Monthly burn',
                  value: CurrencyUtil.formatAmount(
                    (totals['monthly'] as num? ?? 0).toDouble(),
                    code: currency,
                    compact: true,
                  ),
                  icon: LucideIcons.trendingDown,
                  tone: NeoTileTone.coral,
                ),
                NeoStatTile(
                  label: 'Yearly',
                  value: CurrencyUtil.formatAmount(
                    (totals['yearly'] as num? ?? 0).toDouble(),
                    code: currency,
                    compact: true,
                  ),
                  icon: LucideIcons.calendar,
                  tone: NeoTileTone.lemon,
                ),
                NeoStatTile(
                  label: 'Potential / yr',
                  value: CurrencyUtil.formatAmount(
                    (totals['potential_yearly_savings'] as num? ?? 0).toDouble(),
                    code: currency,
                    compact: true,
                  ),
                  icon: LucideIcons.piggyBank,
                  tone: NeoTileTone.mint,
                ),
              ],
            ),
          ),
        ),

        // Cancel candidates
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              emphasised: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Cancel Candidates',
                      trailing: _selected.isEmpty
                          ? null
                          : _SimulateAction(
                              count: _selected.length,
                              saving: selectedSaving,
                              currency: currency,
                              busy: _simulating,
                              onTap: _runSim,
                            )),
                  const SizedBox(height: 12),
                  if (candidates.isEmpty)
                    const EmptyState(
                      kind: EmptyStateKind.trialsClear,
                      title: 'No cuts suggested',
                      subtitle:
                          "You're running a tight ship \u2014 nothing obvious to cancel right now.",
                    )
                  else
                    for (final c in candidates)
                      _CandidateRow(
                        data: c,
                        currency: currency,
                        selected: _selected.contains(c['subscription_id']),
                        onToggle: () {
                          Haptics.light();
                          setState(() {
                            final id = c['subscription_id'] as String;
                            if (!_selected.add(id)) _selected.remove(id);
                          });
                        },
                        onOpen: () => context.push(
                          '/subscriptions/${c['subscription_id']}',
                        ),
                      ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
          ),
        ),

        // What-if
        if (_whatIf != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _WhatIfCard(whatIf: _whatIf!, currency: currency)
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: 0.05),
            ),
          ),

        // Ghosts
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Ghost Subscriptions'),
                  const SizedBox(height: 8),
                  if (ghosts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Every active subscription has recent email activity.',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary(context)),
                      ),
                    )
                  else
                    for (final g in ghosts)
                      _GhostRow(data: g, currency: currency, onOpen: () {
                        context.push('/subscriptions/${g['subscription_id']}');
                      }),
                ],
              ),
            ),
          ),
        ),

        // Annual hints
        if (annualHints.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Switch to Yearly'),
                    const SizedBox(height: 8),
                    for (final a in annualHints)
                      _AnnualHintRow(data: a, currency: currency),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(String title, {Widget? trailing}) => Row(
        children: [
          Text(title.toUpperCase(),
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary(context),
                letterSpacing: 2,
              )),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      );

  Widget _skeleton() => const Center(child: CircularProgressIndicator());

  Widget _error(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Couldn\u2019t load savings \u2014 $message'),
        ),
      );
}

// ─── Row widgets ───

class _CandidateRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String currency;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  const _CandidateRow({
    required this.data,
    required this.currency,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final reason = (data['reason'] as String? ?? 'ghost');
    final saving = (data['yearly_saving'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardFill(context, emphasised: selected),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.cardBorder(context),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.gold,
                      offset: const Offset(3, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              Icon(
                selected ? LucideIcons.checkSquare : LucideIcons.square,
                size: 20,
                color: selected ? AppColors.gold : AppColors.textSecondary(context),
              ),
              const SizedBox(width: 10),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: reason == 'ghost'
                      ? AppColors.lilac(context)
                      : AppColors.coral(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.textPrimary(context),
                    width: 2,
                  ),
                ),
                child: Icon(
                  reason == 'ghost' ? LucideIcons.ghost : LucideIcons.copy,
                  size: 16,
                  color: AppColors.neoInkLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['service_name'] as String? ?? '',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      reason == 'ghost'
                          ? 'No email activity in 60+ days'
                          : 'Possible duplicate plan',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyUtil.formatAmount(saving, code: currency),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text('/yr saving',
                      style: AppTypography.micro.copyWith(
                          color: AppColors.textTertiary(context))),
                ],
              ),
              IconButton(
                icon: Icon(LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textTertiary(context)),
                onPressed: onOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String currency;
  final VoidCallback onOpen;
  const _GhostRow({required this.data, required this.currency, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final cur = data['currency'] as String? ?? currency;
    final cycle = data['billing_cycle'] as String? ?? '';
    final last = data['last_email_detected_at'] as String?;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(LucideIcons.ghost,
                size: 18, color: AppColors.textSecondary(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['service_name'] as String? ?? '',
                      style: AppTypography.body
                          .copyWith(fontWeight: FontWeight.w800)),
                  Text(
                      last != null
                          ? 'Last email ${last.substring(0, 10)}'
                          : 'No email ever received',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary(context))),
                ],
              ),
            ),
            Text(
              '${CurrencyUtil.formatAmount(amount, code: cur)} /$cycle',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnualHintRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String currency;
  const _AnnualHintRow({required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {
    final save = (data['estimated_savings'] as num?)?.toDouble() ?? 0;
    final cur = data['currency'] as String? ?? currency;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, size: 16, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data['service_name'] as String? ?? '',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            'save ~${CurrencyUtil.formatAmount(save, code: cur, compact: true)}/yr',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulateAction extends StatelessWidget {
  final int count;
  final double saving;
  final String currency;
  final bool busy;
  final VoidCallback onTap;
  const _SimulateAction({
    required this.count,
    required this.saving,
    required this.currency,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textPrimary(context), width: 2),
          boxShadow: [
            BoxShadow(color: AppColors.textPrimary(context), offset: const Offset(2, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.zap, size: 14, color: AppColors.neoInkLight),
            const SizedBox(width: 6),
            Text(
              busy
                  ? 'Running\u2026'
                  : '$count \u2022 ${CurrencyUtil.formatAmount(saving, code: currency, compact: true)}/yr',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.neoInkLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatIfCard extends StatelessWidget {
  final Map<String, dynamic> whatIf;
  final String currency;
  const _WhatIfCard({required this.whatIf, required this.currency});

  @override
  Widget build(BuildContext context) {
    final baseline =
        Map<String, dynamic>.from(whatIf['baseline'] as Map? ?? {});
    final projected =
        Map<String, dynamic>.from(whatIf['projected'] as Map? ?? {});
    final saving = Map<String, dynamic>.from(whatIf['saving'] as Map? ?? {});
    final cancelled = whatIf['cancelled_count'] as int? ?? 0;

    return GlassCard(
      tint: AppColors.mint(context),
      emphasised: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHAT-IF',
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary(context),
                letterSpacing: 2.2,
              )),
          const SizedBox(height: 4),
          Text(
            'Cancel $cancelled \u2192 keep ${CurrencyUtil.formatAmount(
              (saving['yearly'] as num? ?? 0).toDouble(),
              code: currency,
              compact: true,
            )}/yr',
            style: AppTypography.sectionTitle.copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From ${CurrencyUtil.formatAmount(
              (baseline['yearly'] as num? ?? 0).toDouble(),
              code: currency,
              compact: true,
            )}/yr \u2192 ${CurrencyUtil.formatAmount(
              (projected['yearly'] as num? ?? 0).toDouble(),
              code: currency,
              compact: true,
            )}/yr',
            style: AppTypography.caption
                .copyWith(color: AppColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }
}
