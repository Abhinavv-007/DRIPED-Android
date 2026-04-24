import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/payment_method.dart';
import '../../../core/utils/brand_asset_resolver.dart';
import '../../../core/widgets/brand_asset_icon.dart';

IconData pmIcon(PaymentMethodType t) {
  switch (t) {
    case PaymentMethodType.creditCard: return LucideIcons.creditCard;
    case PaymentMethodType.debitCard: return LucideIcons.creditCard;
    case PaymentMethodType.upi: return LucideIcons.smartphone;
    case PaymentMethodType.gpay: return LucideIcons.smartphone;
    case PaymentMethodType.phonepe: return LucideIcons.smartphone;
    case PaymentMethodType.paytm: return LucideIcons.smartphone;
    case PaymentMethodType.netBanking: return LucideIcons.building2;
    case PaymentMethodType.paypal: return LucideIcons.globe;
    case PaymentMethodType.other: return LucideIcons.wallet;
  }
}

Widget paymentMethodMark({
  required PaymentMethodType type,
  required String name,
  String? iconSlug,
  required double size,
  Color? fallbackColor,
  EdgeInsetsGeometry padding = EdgeInsets.zero,
}) {
  final fallback = Icon(
    pmIcon(type),
    color: fallbackColor ?? pmAccent(type),
    size: size * 0.9,
  );

  return BrandAssetIcon(
    assetPathFuture: BrandAssetResolver.paymentAsset(
      iconSlug: iconSlug,
      type: type,
      name: name,
    ),
    fallback: fallback,
    size: size,
    padding: padding,
  );
}

Color pmAccent(PaymentMethodType t) {
  switch (t) {
    case PaymentMethodType.creditCard: return const Color(0xFFF5B841);
    case PaymentMethodType.debitCard: return const Color(0xFF06B6D4);
    case PaymentMethodType.upi: return const Color(0xFF8B5CF6);
    case PaymentMethodType.gpay: return const Color(0xFF10B981);
    case PaymentMethodType.phonepe: return const Color(0xFF8B5CF6);
    case PaymentMethodType.paytm: return const Color(0xFF3B82F6);
    case PaymentMethodType.netBanking: return const Color(0xFF64748B);
    case PaymentMethodType.paypal: return const Color(0xFF3B82F6);
    case PaymentMethodType.other: return const Color(0xFFA1A1AA);
  }
}
