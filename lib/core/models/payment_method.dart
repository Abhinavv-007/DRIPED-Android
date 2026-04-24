enum PaymentMethodType {
  creditCard,
  debitCard,
  upi,
  gpay,
  phonepe,
  paytm,
  netBanking,
  paypal,
  other;

  String get wire {
    switch (this) {
      case PaymentMethodType.creditCard:
        return 'credit_card';
      case PaymentMethodType.debitCard:
        return 'debit_card';
      case PaymentMethodType.upi:
        return 'upi';
      case PaymentMethodType.gpay:
        return 'gpay';
      case PaymentMethodType.phonepe:
        return 'phonepe';
      case PaymentMethodType.paytm:
        return 'paytm';
      case PaymentMethodType.netBanking:
        return 'net_banking';
      case PaymentMethodType.paypal:
        return 'paypal';
      case PaymentMethodType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethodType.creditCard:
        return 'Credit Card';
      case PaymentMethodType.debitCard:
        return 'Debit Card';
      case PaymentMethodType.upi:
        return 'UPI';
      case PaymentMethodType.gpay:
        return 'GPay';
      case PaymentMethodType.phonepe:
        return 'PhonePe';
      case PaymentMethodType.paytm:
        return 'Paytm';
      case PaymentMethodType.netBanking:
        return 'Net Banking';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.other:
        return 'Other';
    }
  }

  bool get isCard =>
      this == PaymentMethodType.creditCard ||
      this == PaymentMethodType.debitCard;

  static PaymentMethodType fromWire(String? v) {
    switch (v) {
      case 'credit_card':
      case 'creditcard':
        return PaymentMethodType.creditCard;
      case 'debit_card':
      case 'debitcard':
        return PaymentMethodType.debitCard;
      case 'visa':
      case 'mastercard':
      case 'american_express':
      case 'americanexpress':
      case 'amex':
      case 'rupay':
      case 'diners_club':
      case 'dinersclub':
      case 'discover':
      case 'maestro':
        return PaymentMethodType.creditCard;
      case 'upi':
        return PaymentMethodType.upi;
      case 'gpay':
        return PaymentMethodType.gpay;
      case 'phonepe':
        return PaymentMethodType.phonepe;
      case 'paytm':
        return PaymentMethodType.paytm;
      case 'net_banking':
      case 'bank_transfer':
      case 'netbanking':
      case 'banktransfer':
        return PaymentMethodType.netBanking;
      case 'paypal':
        return PaymentMethodType.paypal;
      default:
        return PaymentMethodType.other;
    }
  }
}

class PaymentMethod {
  final String id;
  final String userId;
  final String name;
  final PaymentMethodType type;
  final String? iconSlug;
  final String? lastFour;
  final int? expiryMonth;
  final int? expiryYear;
  final bool isDefault;
  final DateTime createdAt;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.iconSlug,
    this.lastFour,
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
    required this.createdAt,
  });

  PaymentMethod copyWith({
    String? name,
    PaymentMethodType? type,
    String? iconSlug,
    String? lastFour,
    int? expiryMonth,
    int? expiryYear,
    bool? isDefault,
  }) =>
      PaymentMethod(
        id: id,
        userId: userId,
        name: name ?? this.name,
        type: type ?? this.type,
        iconSlug: iconSlug ?? this.iconSlug,
        lastFour: lastFour ?? this.lastFour,
        expiryMonth: expiryMonth ?? this.expiryMonth,
        expiryYear: expiryYear ?? this.expiryYear,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt,
      );

  String get maskedLabel {
    if (type.isCard && (lastFour ?? '').isNotEmpty) {
      return '$name •• $lastFour';
    }
    return name;
  }

  String? get expiryLabel {
    if (expiryMonth == null || expiryYear == null) return null;
    final mm = expiryMonth!.toString().padLeft(2, '0');
    final yy = (expiryYear! % 100).toString().padLeft(2, '0');
    return '$mm/$yy';
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> m) => PaymentMethod(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        name: m['name'] as String,
        type: PaymentMethodType.fromWire(m['type'] as String?),
        iconSlug: m['icon_slug'] as String?,
        lastFour: m['last_four'] as String?,
        expiryMonth: m['expiry_month'] as int?,
        expiryYear: m['expiry_year'] as int?,
        isDefault: (m['is_default'] as int? ?? 0) == 1,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'type': type.wire,
        'icon_slug': iconSlug,
        'last_four': lastFour,
        'expiry_month': expiryMonth,
        'expiry_year': expiryYear,
        'is_default': isDefault ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };
}
