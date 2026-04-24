import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/subscription.dart';
import '../../../core/models/payment_method.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/urgency.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/service_avatar.dart';
import '../../payment_methods/widgets/pm_icon.dart';

class SubscriptionCard extends ConsumerWidget {
  final Subscription sub;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;
  /// When set by the parent (e.g. for yearly/monthly view), this overrides
  /// the raw sub.amount for display purposes only.
  final double? amountOverride;
  /// Suffix to show next to the overridden amount (e.g. '/yr', '/mo').
  final String? cycleSuffixOverride;

  const SubscriptionCard({
    super.key,
    required this.sub,
    this.selectable = false,
    this.selected = false,
    this.onSelectionChanged,
    this.amountOverride,
    this.cycleSuffixOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pms = ref.watch(paymentMethodsProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    final pm = pms.where((p) => p.id == sub.paymentMethodId).toList();

    final days = sub.daysUntilRenewal;
    final converted = CurrencyUtil.convert(sub.amount, sub.currency, ccy);
    final needsOriginal = sub.currency != ccy;
    final urgency = urgencyFromDays(days);
    final fg = urgencyColour(urgency);
    final textColor = AppColors.textPrimary(context);
    final mutedColor = AppColors.textTertiary(context);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      onTap: () {
        if (selectable) {
          onSelectionChanged?.call(!selected);
          return;
        }
        GoRouter.of(context).go('/subscriptions/${sub.id}');
      },
      onLongPress: () {
        Haptics.medium();
        onSelectionChanged?.call(!selected);
      },
      emphasised: selected,
      borderColour: selected ? AppColors.gold : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(LucideIcons.chevronRight, size: 14, color: mutedColor),
          const SizedBox(width: 2),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Hero(
                tag: 'avatar_${sub.id}',
                child: ServiceAvatar(
                  serviceSlug: sub.serviceSlug,
                  serviceName: sub.serviceName,
                  size: 40,
                ),
              ),
              if (selected)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
                    child: const Icon(LucideIcons.check,
                        size: 10, color: AppColors.ink),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(sub.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle
                              .copyWith(fontSize: 15, color: textColor)),
                    ),
                    const SizedBox(width: 6),
                    if (sub.status == SubscriptionStatus.active)
                      const Icon(LucideIcons.repeat,
                          size: 12, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (pm.isNotEmpty)
                      Flexible(
                        child: _PaymentChip(method: pm.first),
                      ),
                    if (pm.isNotEmpty) const SizedBox(width: 8),
                    Text(
                      sub.renewalDisplayLabel,
                      style: AppTypography.micro.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    CurrencyUtil.formatAmount(
                      amountOverride != null
                          ? CurrencyUtil.convert(amountOverride!, sub.currency, ccy)
                          : converted,
                      code: ccy,
                      decimals: ccy == 'INR' ? 0 : 2,
                    ),
                    style: AppTypography.cardTitle.copyWith(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (needsOriginal && amountOverride == null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${CurrencyUtil.formatAmount(sub.amount, code: sub.currency, decimals: 2)})',
                      style: AppTypography.micro.copyWith(
                          color: mutedColor, fontSize: 10),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                cycleSuffixOverride ?? sub.billingCycle.label,
                style: AppTypography.micro
                    .copyWith(color: mutedColor, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final PaymentMethod method;
  const _PaymentChip({required this.method});

  @override
  Widget build(BuildContext context) {
    final chipFill = AppColors.cardFill(context, emphasised: true);
    final chipBorder = AppColors.cardBorder(context);
    final textColor = AppColors.textSecondary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipFill,
        border: Border.all(color: chipBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          paymentMethodMark(
            type: method.type,
            name: method.name,
            iconSlug: method.iconSlug,
            size: 11,
            fallbackColor: textColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              method.maskedLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.micro.copyWith(
                color: textColor,
                fontSize: 10,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
