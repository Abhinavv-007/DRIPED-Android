import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/billing_cycle.dart';
import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/currency.dart';

/// Formatted amount with optional cycle suffix. Big weight by default.
/// If [targetCurrency] is null, uses the user's preferred currency
/// from [preferredCurrencyProvider] and auto-converts.
class AmountText extends ConsumerWidget {
  final double amount;
  final String currency;
  final String? targetCurrency;
  final BillingCycle? cycle;
  final TextStyle? style;
  final Color? color;
  final bool compact;
  final int? decimals;

  const AmountText({
    super.key,
    required this.amount,
    required this.currency,
    this.targetCurrency,
    this.cycle,
    this.style,
    this.color,
    this.compact = false,
    this.decimals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String target = targetCurrency ?? ref.watch(preferredCurrencyProvider);
    final converted = CurrencyUtil.convert(amount, currency, target);

    final base = style ?? AppTypography.midNumber;
    final clr = color ?? AppColors.textHi;
    final String text = cycle != null
        ? CurrencyUtil.formatContextual(converted, code: target, cycle: cycle!)
        : CurrencyUtil.formatAmount(
            converted,
            code: target,
            compact: compact,
            decimals: decimals ?? (target == 'INR' ? 0 : 2),
          );

    return Semantics(
      label: '$text ${cycle != null ? "per ${cycle!.label}" : ""}',
      child: Text(text, style: base.copyWith(color: clr)),
    );
  }
}
