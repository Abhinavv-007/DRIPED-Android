import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/billing_cycle.dart';
import '../../core/models/subscription.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/urgency.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neo_button.dart';
import '../../core/widgets/service_avatar.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_badge.dart';
import 'add_subscription_sheet.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  final String subscriptionId;
  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  late final TextEditingController _notesCtl;

  @override
  void initState() {
    super.initState();
    final sub = _sub();
    _notesCtl = TextEditingController(text: sub?.notes ?? '');
  }

  Subscription? _sub() {
    final all = ref.read(subscriptionsProvider);
    final m = all.where((s) => s.id == widget.subscriptionId).toList();
    return m.isEmpty ? null : m.first;
  }

  @override
  void dispose() {
    _notesCtl.dispose();
    super.dispose();
  }

  void _update(Subscription s) =>
      ref.read(subscriptionsProvider.notifier).update(s);

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionsProvider).firstWhere(
          (s) => s.id == widget.subscriptionId,
          orElse: () => _MissingSub.build(),
        );
    if (sub.id == 'missing') {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Subscription not found')),
      );
    }

    final cats = ref.watch(categoriesProvider);
    final pms = ref.watch(paymentMethodsProvider);
    final historyAsync = ref.watch(historyForSubscriptionProvider(sub.id));
    final ccy = ref.watch(preferredCurrencyProvider);
    final cat = cats.where((c) => c.id == sub.categoryId).toList();
    final pm = pms.where((p) => p.id == sub.paymentMethodId).toList();
    final shown = CurrencyUtil.convert(sub.amount, sub.currency, ccy);

    final days = sub.daysUntilRenewal;
    final urgency = urgencyFromDays(days);
    final urgClr = urgencyColour(urgency);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _backRow(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Hero(
                      tag: 'avatar_${sub.id}',
                      child: ServiceAvatar(
                        serviceSlug: sub.serviceSlug,
                        serviceName: sub.serviceName,
                        size: 80,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub.serviceName,
                              style: AppTypography.pageTitle
                                  .copyWith(fontSize: 28)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              StatusBadge(status: sub.status),
                              const SizedBox(width: 8),
                              if (cat.isNotEmpty)
                                CategoryChip(
                                    category: cat.first, compact: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _metrics(sub, shown, ccy),
                const SizedBox(height: 20),
                _countdown(sub, days, urgClr),
                const SizedBox(height: 20),
                _remindersCard(sub),
                const SizedBox(height: 20),
                _notesCard(sub),
                const SizedBox(height: 20),
                if (pm.isNotEmpty) _paymentMethodCard(pm.first.maskedLabel),
                if (pm.isNotEmpty) const SizedBox(height: 20),
                historyAsync.when(
                  data: (history) => _historyTimeline(history, ccy),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SkeletonList(count: 3, itemHeight: 48),
                  ),
                  error: (_, __) => _historyTimeline([], ccy),
                ),
                const SizedBox(height: 24),
                _actions(sub),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _backRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Haptics.tap();
            context.pop();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              border: Border.all(color: AppColors.glassBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.arrowLeft,
                size: 20, color: AppColors.textHi),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Haptics.tap();
            final sub = _sub();
            if (sub != null) {
              showEditSubscriptionSheet(context, sub);
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              border: Border.all(color: AppColors.glassBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.pencil,
                size: 18, color: AppColors.textHi),
          ),
        ),
      ],
    );
  }

  Widget _metrics(Subscription sub, double shown, String ccy) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _metric(
            label: 'Amount',
            value: CurrencyUtil.formatAmount(shown,
                code: ccy, decimals: ccy == 'INR' ? 0 : 2),
            colour: AppColors.gold,
          ),
          _divider(),
          _metric(
            label: 'Billing',
            value: sub.billingCycle.label,
          ),
          _divider(),
          _metric(
            label: 'Renewal',
            value: sub.nextRenewalDate == null
                ? '—'
                : DateHelpers.shortDate(sub.nextRenewalDate!),
          ),
        ],
      ),
    );
  }

  Widget _metric({required String label, required String value, Color? colour}) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTypography.midNumber.copyWith(
                  color: colour ?? AppColors.textHi, fontSize: 20)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTypography.micro
                  .copyWith(color: AppColors.textMid)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: AppColors.hairline,
      );

  Widget _countdown(Subscription sub, int? days, Color urgClr) {
    // Smart labels: never show negative day numbers
    final String displayNumber;
    final String subtitle;

    if (days == null) {
      displayNumber = '—';
      subtitle = 'No renewal scheduled';
    } else if (sub.status == SubscriptionStatus.cancelled) {
      displayNumber = '—';
      subtitle = 'Cancelled';
    } else if (sub.status == SubscriptionStatus.archived) {
      displayNumber = '—';
      subtitle = 'Archived';
    } else if (days < -30) {
      displayNumber = '—';
      subtitle = 'Expired';
    } else if (days < 0) {
      displayNumber = '${days.abs()}';
      subtitle = 'days overdue';
    } else if (days == 0) {
      displayNumber = '0';
      subtitle = 'Today';
    } else {
      displayNumber = '$days';
      subtitle = 'days until renewal';
    }

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayNumber,
                style: AppTypography.countdown
                    .copyWith(color: urgClr, fontSize: 84),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle,
                    style: AppTypography.cardTitle
                        .copyWith(color: AppColors.textMid)),
                const SizedBox(height: 6),
                if (sub.isTrial && sub.trialEndDate != null)
                  Text(
                    'Trial ends ${DateHelpers.shortDate(sub.trialEndDate!)}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.warning),
                  ),
                if (sub.nextRenewalDate != null)
                  Text(
                    DateHelpers.longDate(sub.nextRenewalDate!),
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textLow),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 120.ms, duration: 320.ms);
  }

  Widget _remindersCard(Subscription sub) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bell,
                  size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Text('Remind me before renewal',
                  style: AppTypography.cardTitle.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          _reminderRow('7 days before', sub.remind7d,
              (v) => _update(sub.copyWith(remind7d: v))),
          _reminderRow('3 days before', sub.remind3d,
              (v) => _update(sub.copyWith(remind3d: v))),
          _reminderRow('1 day before', sub.remind1d,
              (v) => _update(sub.copyWith(remind1d: v))),
        ],
      ),
    );
  }

  Widget _reminderRow(String label, bool v, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.body)),
          Switch(
            value: v,
            onChanged: (b) {
              Haptics.tap();
              onChanged(b);
            },
          ),
        ],
      ),
    );
  }

  Widget _notesCard(Subscription sub) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileText,
                  size: 16, color: AppColors.textMid),
              const SizedBox(width: 8),
              Text('Notes',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtl,
            minLines: 1,
            maxLines: 4,
            onChanged: (v) => _update(sub.copyWith(notes: v)),
            style: AppTypography.body,
            cursorColor: AppColors.gold,
            decoration: InputDecoration(
              hintText: 'Anything worth remembering',
              hintStyle:
                  AppTypography.body.copyWith(color: AppColors.textLow),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodCard(String label) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: () {
        Haptics.tap();
      },
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              border: Border.all(color: AppColors.glassBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.creditCard,
                size: 18, color: AppColors.textHi),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paid with',
                    style: AppTypography.micro
                        .copyWith(color: AppColors.textMid)),
                const SizedBox(height: 2),
                Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight,
              color: AppColors.textMid, size: 18),
        ],
      ),
    );
  }

  Widget _historyTimeline(List history, String ccy) {
    if (history.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(LucideIcons.history,
                size: 18, color: AppColors.textMid),
            const SizedBox(width: 10),
            Expanded(
                child: Text('No payment history yet.',
                    style: AppTypography.body
                        .copyWith(color: AppColors.textMid))),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.history,
                  size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Text('Payment history',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < history.length; i++)
            _historyRow(history[i], i == history.length - 1, ccy),
        ],
      ),
    );
  }

  Widget _historyRow(dynamic h, bool last, String ccy) {
    final converted = CurrencyUtil.convert(h.amount, h.currency, ccy);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.gold.withOpacity(0.6),
                        blurRadius: 6),
                  ],
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.hairline,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(DateHelpers.longDate(h.chargedAt),
                          style: AppTypography.bodyStrong
                              .copyWith(fontSize: 14)),
                      const Spacer(),
                      Text(
                        CurrencyUtil.formatAmount(converted,
                            code: ccy, decimals: ccy == 'INR' ? 0 : 2),
                        style: AppTypography.bodyStrong
                            .copyWith(color: AppColors.gold),
                      ),
                    ],
                  ),
                  if (h.emailSubject != null) ...[
                    const SizedBox(height: 2),
                    Text(h.emailSubject!,
                        style: AppTypography.caption.copyWith(
                            color: AppColors.textLow)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(Subscription sub) {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            label: sub.status == SubscriptionStatus.paused ? 'Resume' : 'Pause',
            icon: sub.status == SubscriptionStatus.paused
                ? LucideIcons.play
                : LucideIcons.pause,
            colour: AppColors.info,
            onTap: () {
              Haptics.tap();
              ref.read(subscriptionsProvider.notifier).setStatus(
                  sub.id,
                  sub.status == SubscriptionStatus.paused
                      ? SubscriptionStatus.active
                      : SubscriptionStatus.paused);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionBtn(
            label: 'Archive',
            icon: LucideIcons.archive,
            colour: AppColors.warning,
            onTap: () {
              Haptics.medium();
              ref.read(subscriptionsProvider.notifier).archive(sub.id);
              context.pop();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionBtn(
            label: 'Delete',
            icon: LucideIcons.trash2,
            colour: AppColors.danger,
            onTap: () async {
              Haptics.warn();
              final ok = await _confirmDelete(context);
              if (ok == true) {
                ref.read(subscriptionsProvider.notifier).delete(sub.id);
                if (mounted) context.pop();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color colour,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colour.withOpacity(0.1),
          border: Border.all(color: colour.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: colour),
            const SizedBox(height: 2),
            Text(label,
                style: AppTypography.micro.copyWith(
                  color: colour,
                  fontSize: 10,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                )),
          ],
        ),
      ),
    );
  }
}

Future<bool?> _confirmDelete(BuildContext ctx) => showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.inkOverlay,
        title: Text('Delete this subscription?',
            style: AppTypography.sectionTitle),
        content: Text('This cannot be undone.',
            style: AppTypography.body.copyWith(color: AppColors.textMid)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: Text('Cancel',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMid))),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: NeoButton(
              label: 'Delete',
              background: AppColors.danger,
              foreground: Colors.white,
              fullWidth: false,
              height: 42,
              onPressed: () => Navigator.pop(_, true),
            ),
          ),
        ],
      ),
    );

/// Placeholder subscription for the "not found" render path.
class _MissingSub {
  static Subscription build() => Subscription(
        id: 'missing',
        userId: '-',
        serviceName: '—',
        serviceSlug: 'unknown',
        amount: 0,
        billingCycle: BillingCycle.monthly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
