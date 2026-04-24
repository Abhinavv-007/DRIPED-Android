import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/service_avatar.dart';
import '../payment_methods/add_payment_method_sheet.dart';
import '../subscriptions/add_subscription_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _refresh() async {
    Haptics.medium();
    await Future.wait([
      ref.read(subscriptionsProvider.notifier).fetch(),
      ref.read(categoriesProvider.notifier).fetch(),
      ref.read(paymentMethodsProvider.notifier).fetch(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    try {
      final user = ref.watch(currentUserProvider);
      final summary = ref.watch(dashboardSummaryProvider);
      final subscriptions = ref.watch(safeSubscriptionsProvider);
      final paymentMethods = ref.watch(safePaymentMethodsProvider);
      final health = ref.watch(dashboardHealthProvider);
      final ccy = ref.watch(preferredCurrencyProvider);
      final now = DateTime.now();

      final displayName = user == null || (user.fullName ?? '').trim().isEmpty
          ? 'Demo User'
          : user.fullName!.trim();
      final avatarInitial = displayName.isNotEmpty ? displayName[0] : 'D';

      final upcoming = (subscriptions ?? [])
          .where((s) {
            if (s == null) return false;
            final days = s.daysUntilRenewal;
            return days != null && days >= 0 && days <= 30;
          })
          .take(4)
          .toList();

      final walletRows = <_HomeWalletRow>[];
      for (final pm in (paymentMethods ?? [])) {
        if (pm == null) continue;
        final linked = (subscriptions ?? []).where((s) => s?.paymentMethodId == pm.id);
        var monthly = 0.0;
        var count = 0;
        for (final sub in linked) {
          if (sub == null) continue;
          count++;
          monthly += CurrencyUtil.convert(
            sub.billingCycle.toMonthly(sub.amount),
            sub.currency,
            ccy ?? 'USD',
          );
        }
        if (count == 0) continue;
        walletRows.add(
          _HomeWalletRow(
            id: pm.id,
            title: pm.maskedLabel,
            subtitle: '$count ${count == 1 ? 'subscription' : 'subscriptions'}',
            iconSlug: pm.iconSlug,
            amountLabel:
                '${CurrencyUtil.formatAmount(monthly, code: ccy ?? 'USD', compact: true)}/mo',
          ),
        );
        if (walletRows.length == 3) break;
      }

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.gold,
            backgroundColor:
                AppColors.isDark(context) ? AppColors.inkRaised : Colors.white,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: CustomHeader(
                    leading: HeaderAvatar(
                      imageUrl: user?.avatarUrl,
                      fallbackInitial: avatarInitial,
                      onTap: () => context.go('/profile'),
                    ),
                    title: displayName,
                    subtitle:
                        '${_greetingFor(now.hour)} • ${DateFormat('MMMM yyyy').format(now)}',
                    actions: [
                      HeaderAction(
                        icon: LucideIcons.piggyBank,
                        onTap: () => context.push('/savings'),
                        tooltip: 'Savings',
                      ),
                      HeaderAction(
                        icon: LucideIcons.trendingUp,
                        onTap: () => context.push('/forecast'),
                        tooltip: 'Forecast',
                      ),
                      HeaderAction(
                        icon: LucideIcons.bell,
                        onTap: () => context.go('/profile'),
                        badge: summary != null && summary.trialsEndingSoon > 0,
                        tooltip: 'Alerts',
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, duration: 400.ms, curve: Curves.easeOutCubic),
                ),

                SliverToBoxAdapter(
                  child: _HeroSpendCard(
                    monthlyTotal: CurrencyUtil.convert(
                      summary?.monthlyTotalINR ?? 0.0,
                      'INR',
                      ccy ?? 'USD',
                    ),
                    yearlyTotal: CurrencyUtil.convert(
                      summary?.yearlyTotalINR ?? 0.0,
                      'INR',
                      ccy ?? 'USD',
                    ),
                    activeCount: summary?.activeCount ?? 0,
                    trialsEndingSoon: summary?.trialsEndingSoon ?? 0,
                    currency: ccy ?? 'USD',
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                ),
                if (subscriptions == null || subscriptions.isEmpty)
                  SliverToBoxAdapter(
                    child: _StarterPanel(
                      hasPaymentMethods: paymentMethods != null && paymentMethods.isNotEmpty,
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05),
                  ),
                SliverToBoxAdapter(
                  child: _HomeSectionCard(
                    title: 'Renewing soon',
                    trailingLabel: upcoming.isEmpty ? null : 'View all',
                    onTap: upcoming.isEmpty
                        ? null
                        : () => context.go('/subscriptions'),
                    child: upcoming.isEmpty
                        ? const _EmptyText(
                            text:
                                'No renewals in the next 30 days. Pull down to refresh after a Gmail sync.',
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < upcoming.length; i++) ...[
                                if (i > 0) const _SoftDivider(),
                                _UpcomingRow(
                                  serviceSlug: upcoming[i].serviceSlug,
                                  serviceName: upcoming[i].serviceName,
                                  amount: CurrencyUtil.convert(
                                    upcoming[i].amount,
                                    upcoming[i].currency,
                                    ccy ?? 'USD',
                                  ),
                                  ccy: ccy ?? 'USD',
                                  renewalLabel: upcoming[i].renewalDisplayLabel,
                                ),
                              ],
                            ],
                          ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05),
                ),
                SliverToBoxAdapter(
                  child: _HomeSectionCard(
                    title: 'Wallet overview',
                    trailingLabel: paymentMethods?.isEmpty ?? true ? null : 'Manage',
                    onTap: paymentMethods?.isEmpty ?? true
                        ? null
                        : () => context.go('/payments'),
                    child: paymentMethods?.isEmpty ?? true
                        ? const _EmptyText(
                            text:
                                'No payment methods yet. Add a card or wallet to see which method funds each renewal.',
                          )
                        : walletRows.isEmpty
                            ? const _EmptyText(
                                text:
                                    'Payment methods are ready. Link them while adding subscriptions.',
                              )
                            : Column(
                                children: [
                                  for (int i = 0;
                                      i < walletRows.length;
                                      i++) ...[
                                    if (i > 0) const _SoftDivider(),
                                    _WalletRow(
                                      row: walletRows[i],
                                      onTap: () => context.go(
                                        '/payments/${walletRows[i].id}',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                  ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.05),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 154)),
              ],
            ),
          ),
        ),
      );
    } catch (error, stack) {
      debugPrint('HomeScreen Dashboard Error: $error\n$stack');
      return _HomeErrorState(
        message: 'Dashboard data could not be rendered safely.',
        detail: error.toString(),
        onRetry: () => setState(() {}),
      );
    }
  }

  String _greetingFor(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HeroSpendCard extends StatelessWidget {
  final double monthlyTotal;
  final double yearlyTotal;
  final int activeCount;
  final int trialsEndingSoon;
  final String currency;

  const _HeroSpendCard({
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.activeCount,
    required this.trialsEndingSoon,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final average = activeCount == 0 ? 0.0 : monthlyTotal / activeCount;
    final isEmpty = activeCount == 0 && monthlyTotal <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: GlassCard(
        emphasised: true,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AccentIcon(icon: LucideIcons.wallet, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly spend',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEmpty
                            ? 'No active recurring charges yet'
                            : '$activeCount active recurring ${activeCount == 1 ? 'charge' : 'charges'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trialsEndingSoon > 0) ...[
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: '$trialsEndingSoon trial',
                    color: AppColors.warning,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  CurrencyUtil.formatAmount(
                    monthlyTotal,
                    code: currency,
                    compact: monthlyTotal >= 100000,
                  ),
                  style: AppTypography.heroNumber.copyWith(
                    color: AppColors.textPrimary(context),
                    fontSize: 54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              yearlyTotal <= 0
                  ? 'Add a subscription or scan Gmail to unlock your live spend pulse.'
                  : 'Projected yearly run rate: ${CurrencyUtil.formatAmount(yearlyTotal, code: currency, compact: true)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Yearly',
                    value: CurrencyUtil.formatAmount(
                      yearlyTotal,
                      code: currency,
                      compact: true,
                    ),
                    icon: LucideIcons.calendar,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Average',
                    value: average <= 0
                        ? '—'
                        : '${CurrencyUtil.formatAmount(average, code: currency, compact: true)}/sub',
                    icon: LucideIcons.activity,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardFill(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.micro.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.textPrimary(context),
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _StarterPanel extends StatelessWidget {
  final bool hasPaymentMethods;
  const _StarterPanel({required this.hasPaymentMethods});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start tracking',
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.textPrimary(context),
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              hasPaymentMethods
                  ? 'Add your first subscription or run Gmail scan from Profile.'
                  : 'Add one subscription and one payment method to activate the dashboard.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 330;
                final buttons = [
                  _ActionButton(
                    icon: LucideIcons.plus,
                    label: 'Add subscription',
                    color: AppColors.gold,
                    onTap: () => showAddSubscriptionSheet(context),
                  ),
                  _ActionButton(
                    icon: hasPaymentMethods
                        ? LucideIcons.mailSearch
                        : LucideIcons.creditCard,
                    label: hasPaymentMethods ? 'Scan Gmail' : 'Add payment',
                    color:
                        hasPaymentMethods ? AppColors.success : AppColors.info,
                    onTap: () => hasPaymentMethods
                        ? context.go('/profile')
                        : showAddPaymentMethodSheet(context),
                  ),
                ];

                if (stack) {
                  return Column(
                    children: [
                      buttons[0],
                      const SizedBox(height: 10),
                      buttons[1],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: buttons[0]),
                    const SizedBox(width: 10),
                    Expanded(child: buttons[1]),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSectionCard extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final Widget child;

  const _HomeSectionCard({
    required this.title,
    required this.child,
    this.trailingLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                if (trailingLabel != null && onTap != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Haptics.tap();
                      onTap!();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Text(
                        trailingLabel!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final String serviceSlug;
  final String serviceName;
  final double amount;
  final String ccy;
  final String renewalLabel;

  const _UpcomingRow({
    required this.serviceSlug,
    required this.serviceName,
    required this.amount,
    required this.ccy,
    required this.renewalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ServiceAvatar(
          serviceSlug: serviceSlug,
          serviceName: serviceName,
          size: 42,
          glow: true,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.textPrimary(context),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                renewalLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 112),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              CurrencyUtil.formatAmount(amount, code: ccy, compact: true),
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.textPrimary(context),
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeWalletRow {
  final String id;
  final String title;
  final String subtitle;
  final String? iconSlug;
  final String amountLabel;

  const _HomeWalletRow({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconSlug,
    required this.amountLabel,
  });
}

class _WalletRow extends StatelessWidget {
  final _HomeWalletRow row;
  final VoidCallback onTap;

  const _WalletRow({
    required this.row,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cardFill(context, emphasised: true),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            alignment: Alignment.center,
            child: row.iconSlug == null
                ? Icon(
                    LucideIcons.creditCard,
                    size: 20,
                    color: AppColors.textSecondary(context),
                  )
                : ServiceAvatar(
                    serviceSlug: row.iconSlug!,
                    serviceName: row.title,
                    size: 28,
                    glow: false,
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.textPrimary(context),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                row.amountLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _AccentIcon({
    required this.icon,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: color.withOpacity(0.34)),
      ),
      child: Icon(icon, size: size * 0.48, color: color),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: AppTypography.micro.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.ink, size: 18),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.buttonMd.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: AppColors.divider(context),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary(context),
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _HomeErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    color: AppColors.danger,
                    size: 42,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: LucideIcons.refreshCw,
                    label: 'Reload dashboard',
                    color: AppColors.gold,
                    onTap: onRetry,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
