import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/payment_method.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neo_button.dart';
import '../../core/widgets/service_avatar.dart';
import 'add_payment_method_sheet.dart';
import 'widgets/pm_icon.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pms = ref.watch(safePaymentMethodsProvider);
    final subs = ref.watch(liveSubscriptionsProvider);
    final ccy = ref.watch(preferredCurrencyProvider);

    final totalMonthly = subs.fold<double>(0, (a, s) {
      return a +
          CurrencyUtil.convert(
              s.billingCycle.toMonthly(s.amount), s.currency, ccy);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CustomHeader(
                title: 'Payments',
                subtitle:
                    '${pms.length} method${pms.length == 1 ? '' : 's'}  ·  ${subs.length} subs',
                actions: pms.isEmpty
                    ? const []
                    : [
                        HeaderAction(
                          icon: LucideIcons.plus,
                          onTap: () => showAddPaymentMethodSheet(context),
                        ),
                      ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  emphasised: true,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly outflow',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary(context),
                                  letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          AnimatedCurrency(
                            value: totalMonthly,
                            currency: ccy,
                            compact: true,
                            color: AppColors.gold,
                            style: AppTypography.midNumber,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold.withOpacity(0.3),
                              AppColors.goldDeep.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: const Icon(LucideIcons.wallet,
                            color: AppColors.gold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (pms.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 30, 30, 154),
                  child: EmptyState(
                    kind: EmptyStateKind.paymentMethods,
                    title: 'No payment methods yet',
                    subtitle: 'Add one to track which card is paying for what.',
                    action: NeoButton(
                      label: 'Add payment method',
                      leading: LucideIcons.plus,
                      onPressed: () => showAddPaymentMethodSheet(context),
                      fullWidth: false,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 154),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final pm = pms[i];
                      final linked = subs
                          .where((s) => s.paymentMethodId == pm.id)
                          .toList();
                      final spend = linked.fold<double>(
                          0,
                          (a, s) =>
                              a +
                              CurrencyUtil.convert(
                                  s.billingCycle.toMonthly(s.amount),
                                  s.currency,
                                  ccy));
                      return _PmCard(
                              pm: pm,
                              subCount: linked.length,
                              spend: spend,
                              ccy: ccy,
                              linkedSubs: linked)
                          .animate()
                          .fadeIn(delay: (i * 40).ms, duration: 260.ms)
                          .slideY(
                              begin: 0.06,
                              end: 0,
                              duration: 300.ms,
                              curve: Curves.easeOutCubic);
                    },
                    childCount: pms.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PmCard extends StatelessWidget {
  final PaymentMethod pm;
  final int subCount;
  final double spend;
  final String ccy;
  final List linkedSubs;
  const _PmCard({
    required this.pm,
    required this.subCount,
    required this.spend,
    required this.ccy,
    required this.linkedSubs,
  });

  @override
  Widget build(BuildContext context) {
    final accent = pmAccent(pm.type);
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    final mutedColor = AppColors.textTertiary(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      tint: accent.withOpacity(0.08),
      borderColour: accent.withOpacity(0.24),
      onTap: () {
        Haptics.tap();
        GoRouter.of(context).go('/payments/${pm.id}');
      },
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -18,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.14,
                child: Transform.rotate(
                  angle: -0.18,
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: Center(
                      child: paymentMethodMark(
                        type: pm.type,
                        name: pm.name,
                        iconSlug: pm.iconSlug,
                        size: 58,
                        fallbackColor: accent,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.18),
                      border: Border.all(color: accent, width: 1.4),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: accent.withOpacity(0.35),
                            blurRadius: 10,
                            spreadRadius: 0.5),
                      ],
                    ),
                    child: Center(
                      child: paymentMethodMark(
                        type: pm.type,
                        name: pm.name,
                        iconSlug: pm.iconSlug,
                        size: 16,
                        fallbackColor: accent,
                        padding: const EdgeInsets.all(1.5),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withOpacity(0.32)),
                    ),
                    child: Text(
                      pm.type.label.toUpperCase(),
                      style: AppTypography.micro.copyWith(
                        color: accent,
                        fontSize: 9,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (pm.isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: Text('DEFAULT',
                          style: AppTypography.micro.copyWith(
                            color: AppColors.gold,
                            fontSize: 9,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w900,
                          )),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(pm.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle
                      .copyWith(color: textColor, fontSize: 17)),
              const SizedBox(height: 4),
              Text(
                pm.maskedLabel != pm.name
                    ? '•• ${pm.lastFour ?? ''}'
                    : pm.type.label,
                style: AppTypography.micro.copyWith(color: subColor),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$subCount subs',
                            style: AppTypography.micro
                                .copyWith(color: mutedColor)),
                        const SizedBox(height: 3),
                        Text(
                          subCount == 0
                              ? 'No linked spend'
                              : '${CurrencyUtil.formatAmount(spend, code: ccy, compact: true)}/mo',
                          style: AppTypography.caption.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (linkedSubs.isNotEmpty)
                    SizedBox(
                      width: 54,
                      height: 22,
                      child: Stack(
                        children: [
                          for (int i = 0;
                              i < linkedSubs.length.clamp(0, 3);
                              i++)
                            Positioned(
                              left: i * 14.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.cardBorder(context,
                                          strong: true),
                                      width: 1.5),
                                ),
                                child: ServiceAvatar(
                                  serviceSlug: linkedSubs[i].serviceSlug,
                                  serviceName: linkedSubs[i].serviceName,
                                  size: 22,
                                  glow: false,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
