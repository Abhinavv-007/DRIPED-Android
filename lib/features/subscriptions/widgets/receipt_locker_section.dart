import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/skeleton.dart';

/// Drop-in section for `SubscriptionDetailScreen` that lists every email
/// receipt associated with the subscription.
class ReceiptLockerSection extends ConsumerWidget {
  final String subscriptionId;
  const ReceiptLockerSection({super.key, required this.subscriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(receiptsForSubscriptionProvider(subscriptionId));
    final currency = ref.watch(preferredCurrencyProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.receipt, size: 16,
                  color: AppColors.textSecondary(context)),
              const SizedBox(width: 8),
              Text('RECEIPT LOCKER',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary(context),
                    letterSpacing: 2,
                  )),
              const Spacer(),
              async.when(
                data: (r) => Text('${r.length}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary(context),
                    )),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          async.when(
            data: (receipts) {
              if (receipts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(LucideIcons.mail,
                            size: 22,
                            color: AppColors.textTertiary(context)),
                        const SizedBox(height: 6),
                        Text(
                          'No receipts yet. Run a Gmail scan to populate.',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final r in receipts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.mail,
                              size: 16, color: AppColors.gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.subject ?? '(no subject)',
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (r.sender != null)
                                  Text(
                                    r.sender!,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textTertiary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (r.snippet != null)
                                  Text(
                                    r.snippet!,
                                    style: AppTypography.micro.copyWith(
                                      color: AppColors.textTertiary(context),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (r.amount != null)
                                Text(
                                  CurrencyUtil.formatAmount(
                                    r.amount!,
                                    code: r.currency ?? currency,
                                  ),
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              if (r.chargedAt != null)
                                Text(
                                  DateFormat('d MMM y').format(r.chargedAt!),
                                  style: AppTypography.micro.copyWith(
                                    color: AppColors.textTertiary(context),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            loading: () => Column(
              children: List.generate(3, (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Skeleton(width: double.infinity, height: 44),
              )),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Couldn\u2019t load receipts.',
                style: AppTypography.caption.copyWith(color: AppColors.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
