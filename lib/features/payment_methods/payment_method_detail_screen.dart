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
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neo_button.dart';
import '../subscriptions/widgets/subscription_card.dart';
import 'widgets/pm_icon.dart';

class PaymentMethodDetailScreen extends ConsumerWidget {
  final String paymentMethodId;
  const PaymentMethodDetailScreen(
      {super.key, required this.paymentMethodId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pms = ref.watch(paymentMethodsProvider);
    final match = pms.where((p) => p.id == paymentMethodId).toList();
    if (match.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: EmptyState(
              kind: EmptyStateKind.paymentMethods,
              title: 'Payment method missing',
              subtitle: 'It may have been deleted.',
              action: NeoButton(
                label: 'Back',
                leading: LucideIcons.arrowLeft,
                onPressed: () => context.go('/payments'),
                fullWidth: false,
              ),
            ),
          ),
        ),
      );
    }
    final pm = match.first;
    final subs = ref.watch(subsByPaymentMethodProvider(pm.id));
    final ccy = ref.watch(preferredCurrencyProvider);
    final accent = pmAccent(pm.type);
    final monthly = subs.fold<double>(
        0,
        (a, s) =>
            a +
            CurrencyUtil.convert(
                s.billingCycle.toMonthly(s.amount), s.currency, ccy));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _roundBtn(LucideIcons.arrowLeft, () {
                    Haptics.tap();
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/payments');
                    }
                  }),
                  const Spacer(),
                  if (!pm.isDefault)
                    _roundBtn(LucideIcons.star, () {
                      Haptics.success();
                      ref
                          .read(paymentMethodsProvider.notifier)
                          .makeDefault(pm.id);
                    }),
                  const SizedBox(width: 10),
                  _roundBtn(LucideIcons.trash2, () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppColors.inkOverlay,
                        title: Text('Delete method?',
                            style: AppTypography.sectionTitle),
                        content: Text(
                          subs.isEmpty
                              ? 'This will be gone.'
                              : '${subs.length} subscription${subs.length == 1 ? '' : 's'} still use this. They will be unlinked.',
                          style: AppTypography.body
                              .copyWith(color: AppColors.textMid),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: Text('Cancel',
                                style: AppTypography.body
                                    .copyWith(color: AppColors.textMid)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: Text('Delete',
                                style: AppTypography.body.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      ref
                          .read(paymentMethodsProvider.notifier)
                          .delete(pm.id);
                      if (context.mounted) context.go('/payments');
                    }
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: _HeroCard(pm: pm, accent: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.textMid,
                                  letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          AnimatedCurrency(
                            value: monthly,
                            currency: ccy,
                            compact: true,
                            color: AppColors.gold,
                            style: AppTypography.cardTitle.copyWith(fontSize: 22),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 36,
                        color: AppColors.hairline),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subs',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.textMid,
                                  letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text('${subs.length}',
                              style: AppTypography.cardTitle
                                  .copyWith(fontSize: 22)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Linked subscriptions',
                  style: AppTypography.sectionTitle),
            ),
            if (subs.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: EmptyState(
                  kind: EmptyStateKind.subscriptions,
                  title: 'Nothing using this card',
                  subtitle: 'Link a subscription to track what it pays for.',
                ),
              )
            else
              ...List.generate(subs.length, (i) {
                final s = subs[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: SubscriptionCard(sub: s)
                      .animate()
                      .fadeIn(delay: (i * 40).ms, duration: 240.ms)
                      .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 280.ms,
                          curve: Curves.easeOutCubic),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          border: Border.all(color: AppColors.glassBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textMid, size: 18),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final dynamic pm;
  final Color accent;
  const _HeroCard({required this.pm, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.28),
            accent.withOpacity(0.08),
            AppColors.glassFill,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent, width: 1.5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: accent.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 1),
          const BoxShadow(
              color: AppColors.shadowInk, offset: Offset(5, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              paymentMethodMark(
                type: pm.type,
                name: pm.name,
                iconSlug: pm.iconSlug,
                size: 28,
                fallbackColor: accent,
                padding: const EdgeInsets.all(2),
              ),
              const Spacer(),
              if (pm.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Text('DEFAULT',
                      style: AppTypography.micro.copyWith(
                          color: AppColors.gold,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
              pm.lastFour == null ? '•• •• •• ••' : '•• •• •• ${pm.lastFour}',
              style: AppTypography.cardTitle.copyWith(
                  fontSize: 22, letterSpacing: 3, color: AppColors.text)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CARDHOLDER',
                        style: AppTypography.micro.copyWith(
                            color: AppColors.textLow,
                            fontSize: 9,
                            letterSpacing: 1.4)),
                    const SizedBox(height: 4),
                    Text(pm.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              if (pm.expiryLabel != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('EXPIRES',
                        style: AppTypography.micro.copyWith(
                            color: AppColors.textLow,
                            fontSize: 9,
                            letterSpacing: 1.4)),
                    const SizedBox(height: 4),
                    Text(pm.expiryLabel,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
