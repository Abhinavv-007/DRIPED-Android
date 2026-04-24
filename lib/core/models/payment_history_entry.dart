class PaymentHistoryEntry {
  final String id;
  final String userId;
  final String subscriptionId;
  final double amount;
  final String currency;
  final DateTime chargedAt;
  final String? emailSubject;
  final String? paymentMethodHint;

  const PaymentHistoryEntry({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.amount,
    this.currency = 'INR',
    required this.chargedAt,
    this.emailSubject,
    this.paymentMethodHint,
  });

  factory PaymentHistoryEntry.fromMap(Map<String, dynamic> m) =>
      PaymentHistoryEntry(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        subscriptionId: m['subscription_id'] as String,
        amount: (m['amount'] as num).toDouble(),
        currency: (m['currency'] as String?) ?? 'INR',
        chargedAt: DateTime.parse(m['charged_at'] as String),
        emailSubject: m['email_subject'] as String?,
        paymentMethodHint: m['payment_method_hint'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'subscription_id': subscriptionId,
        'amount': amount,
        'currency': currency,
        'charged_at': chargedAt.toIso8601String(),
        'email_subject': emailSubject,
        'payment_method_hint': paymentMethodHint,
      };
}
