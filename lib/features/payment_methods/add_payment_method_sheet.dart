import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/payment_method.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/brand_asset_resolver.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/drag_handle.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neo_button.dart';
import 'widgets/pm_icon.dart';

Future<void> showAddPaymentMethodSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => const _AddPaymentMethodSheet(),
  );
}

class _AddPaymentMethodSheet extends ConsumerStatefulWidget {
  const _AddPaymentMethodSheet();

  @override
  ConsumerState<_AddPaymentMethodSheet> createState() =>
      _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState
    extends ConsumerState<_AddPaymentMethodSheet> {
  final _nameCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  final _lastFourCtl = TextEditingController();
  final _mmCtl = TextEditingController();
  final _yyCtl = TextEditingController();
  PaymentMethodType _type = PaymentMethodType.creditCard;
  String? _selectedIconSlug;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _selectedIconSlug = _defaultIconSlugForType(_type);
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _notesCtl.dispose();
    _lastFourCtl.dispose();
    _mmCtl.dispose();
    _yyCtl.dispose();
    super.dispose();
  }

  bool get _showsNameField =>
      _type.isCard ||
      _type == PaymentMethodType.upi ||
      _type == PaymentMethodType.netBanking ||
      _type == PaymentMethodType.other;

  bool get _showsNotesField => _type == PaymentMethodType.other;

  bool get _canSave {
    switch (_type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return _nameCtl.text.trim().isNotEmpty &&
            _lastFourCtl.text.trim().length == 4;
      case PaymentMethodType.upi:
      case PaymentMethodType.netBanking:
      case PaymentMethodType.other:
        return _nameCtl.text.trim().isNotEmpty;
      case PaymentMethodType.gpay:
      case PaymentMethodType.phonepe:
      case PaymentMethodType.paytm:
      case PaymentMethodType.paypal:
        return true;
    }
  }

  String get _typeSummary {
    switch (_type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return 'Save the card nickname, last four digits, and expiry so subscriptions can be mapped cleanly.';
      case PaymentMethodType.upi:
        return 'Track a raw UPI handle directly with its UPI ID.';
      case PaymentMethodType.gpay:
        return 'Brand this payment rail as Google Pay. No extra fields needed.';
      case PaymentMethodType.phonepe:
        return 'Brand this payment rail as PhonePe. No extra fields needed.';
      case PaymentMethodType.paytm:
        return 'Brand this payment rail as Paytm. No extra fields needed.';
      case PaymentMethodType.netBanking:
        return 'Use the bank or account label you want to see across linked subscriptions.';
      case PaymentMethodType.paypal:
        return 'Use PayPal branding directly without extra account details.';
      case PaymentMethodType.other:
        return 'Capture a custom wallet or payment rail with a name and short note.';
    }
  }

  String get _nameLabel {
    switch (_type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return 'Card name';
      case PaymentMethodType.upi:
        return 'UPI ID';
      case PaymentMethodType.netBanking:
        return 'Bank name';
      case PaymentMethodType.other:
        return 'Name';
      case PaymentMethodType.gpay:
      case PaymentMethodType.phonepe:
      case PaymentMethodType.paytm:
      case PaymentMethodType.paypal:
        return 'Name';
    }
  }

  String get _nameHint {
    switch (_type) {
      case PaymentMethodType.creditCard:
        return 'HDFC Millennia Credit';
      case PaymentMethodType.debitCard:
        return 'Axis Debit Everyday';
      case PaymentMethodType.upi:
        return 'name@okhdfcbank';
      case PaymentMethodType.netBanking:
        return 'HDFC Net Banking';
      case PaymentMethodType.other:
        return 'Wallet / family account';
      case PaymentMethodType.gpay:
        return 'Google Pay';
      case PaymentMethodType.phonepe:
        return 'PhonePe';
      case PaymentMethodType.paytm:
        return 'Paytm';
      case PaymentMethodType.paypal:
        return 'PayPal';
    }
  }

  String get _resolvedName {
    final typedName = _nameCtl.text.trim();
    switch (_type) {
      case PaymentMethodType.gpay:
        return 'Google Pay';
      case PaymentMethodType.phonepe:
        return 'PhonePe';
      case PaymentMethodType.paytm:
        return 'Paytm';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.other:
        final note = _notesCtl.text.trim();
        if (typedName.isEmpty) return 'Other';
        return note.isEmpty ? typedName : '$typedName • $note';
      default:
        if (typedName.isNotEmpty) return typedName;
        return _selectedBrand?.label ?? '';
    }
  }

  _PaymentBrandOption? get _selectedBrand {
    final slug = _selectedIconSlug;
    if (slug == null) return null;
    for (final option in _brandOptionsForType(_type)) {
      if (option.slug == slug) return option;
    }
    return null;
  }

  List<_PaymentBrandOption> _brandOptionsForType(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return const [
          _PaymentBrandOption('visa', 'Visa'),
          _PaymentBrandOption('mastercard', 'Mastercard'),
          _PaymentBrandOption('rupay', 'RuPay'),
          _PaymentBrandOption('americanexpress', 'AmEx'),
          _PaymentBrandOption('discover', 'Discover'),
          _PaymentBrandOption('dinersclub', 'Diners'),
          _PaymentBrandOption('maestro', 'Maestro'),
        ];
      case PaymentMethodType.upi:
        return const [
          _PaymentBrandOption('upi', 'UPI'),
          _PaymentBrandOption('googlepay', 'GPay'),
          _PaymentBrandOption('phonepe', 'PhonePe'),
          _PaymentBrandOption('paytm', 'Paytm'),
          _PaymentBrandOption('amazonpay', 'Amazon Pay'),
        ];
      case PaymentMethodType.gpay:
        return const [_PaymentBrandOption('googlepay', 'Google Pay')];
      case PaymentMethodType.phonepe:
        return const [_PaymentBrandOption('phonepe', 'PhonePe')];
      case PaymentMethodType.paytm:
        return const [_PaymentBrandOption('paytm', 'Paytm')];
      case PaymentMethodType.paypal:
        return const [_PaymentBrandOption('paypal', 'PayPal')];
      case PaymentMethodType.netBanking:
        return const [
          _PaymentBrandOption('hdfcbank', 'HDFC'),
          _PaymentBrandOption('icicibank', 'ICICI'),
          _PaymentBrandOption('sbi', 'SBI'),
          _PaymentBrandOption('axisbank', 'Axis'),
          _PaymentBrandOption('idfcfirst', 'IDFC First'),
          _PaymentBrandOption('barclays', 'Barclays'),
          _PaymentBrandOption('chase', 'Chase'),
          _PaymentBrandOption('bankofamerica', 'BoA'),
        ];
      case PaymentMethodType.other:
        return const [
          _PaymentBrandOption('wallet', 'Wallet'),
          _PaymentBrandOption('btc', 'Crypto'),
          _PaymentBrandOption('binance', 'Binance'),
          _PaymentBrandOption('binancepay', 'Binance Pay'),
          _PaymentBrandOption('banktransfer', 'Bank Transfer'),
          _PaymentBrandOption('paypal', 'PayPal'),
          _PaymentBrandOption('stripe', 'Stripe'),
          _PaymentBrandOption('wise', 'Wise'),
          _PaymentBrandOption('payoneer', 'Payoneer'),
          _PaymentBrandOption('venmo', 'Venmo'),
          _PaymentBrandOption('cashapp', 'Cash App'),
          _PaymentBrandOption('revolut', 'Revolut'),
          _PaymentBrandOption('applepay', 'Apple Pay'),
          _PaymentBrandOption('samsungpay', 'Samsung Pay'),
          _PaymentBrandOption('amazonpay', 'Amazon Pay'),
          _PaymentBrandOption('klarna', 'Klarna'),
          _PaymentBrandOption('afterpay', 'Afterpay'),
          _PaymentBrandOption('alipay', 'Alipay'),
        ];
    }
  }

  String? _defaultIconSlugForType(PaymentMethodType type) {
    return switch (type) {
      PaymentMethodType.gpay => 'googlepay',
      PaymentMethodType.phonepe => 'phonepe',
      PaymentMethodType.paytm => 'paytm',
      PaymentMethodType.paypal => 'paypal',
      _ => null,
    };
  }

  void _selectType(PaymentMethodType type) {
    if (_type == type) return;
    final nextOptions = _brandOptionsForType(type);
    setState(() {
      _type = type;
      if (!type.isCard) {
        _lastFourCtl.clear();
        _mmCtl.clear();
        _yyCtl.clear();
      }
      if (type != PaymentMethodType.other) {
        _notesCtl.clear();
      }
      if (!_showsNameField) {
        _nameCtl.clear();
      }
      final nextDefault = _defaultIconSlugForType(type);
      if (nextDefault != null) {
        _selectedIconSlug = nextDefault;
      } else if (!nextOptions.any((option) => option.slug == _selectedIconSlug)) {
        _selectedIconSlug = null;
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final m = int.tryParse(_mmCtl.text);
    final y = int.tryParse(_yyCtl.text);
    final resolvedName = _resolvedName;
    final pm = PaymentMethod(
      id: newId(),
      userId: ref.read(currentUserProvider).id,
      name: resolvedName,
      type: _type,
      iconSlug: _selectedIconSlug ??
          BrandAssetResolver.suggestPaymentIconSlug(
            type: _type,
            name: resolvedName,
          ),
      lastFour: _type.isCard ? _lastFourCtl.text : null,
      expiryMonth: _type.isCard ? m : null,
      expiryYear: _type.isCard && y != null ? (y < 100 ? 2000 + y : y) : null,
      isDefault: _isDefault,
      createdAt: DateTime.now(),
    );
    await ref.read(paymentMethodsProvider.notifier).add(pm);
    if (!mounted) return;
    Haptics.success();
    Navigator.of(context).pop(pm.id);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final isDark = AppColors.isDark(context);
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    final sheetSurface = isDark ? AppColors.inkRaised : AppColors.lightCard;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        decoration: BoxDecoration(
          color: sheetSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(color: AppColors.cardBorder(context, strong: true)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const DragHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                child: Row(
                  children: [
                    Text(
                      'Add payment method',
                      style:
                          AppTypography.sectionTitle.copyWith(color: textColor),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        LucideIcons.x,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  children: [
                    _label('Type', context),
                    SizedBox(
                      height: 46,
                      child: Builder(
                        builder: (context) {
                          // Only show consolidated types — individual UPI apps
                          // are available as brand options under UPI / Other.
                          const visibleTypes = [
                            PaymentMethodType.creditCard,
                            PaymentMethodType.debitCard,
                            PaymentMethodType.upi,
                            PaymentMethodType.netBanking,
                            PaymentMethodType.other,
                          ];
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: visibleTypes.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final t = visibleTypes[i];
                              final sel = t == _type;
                              final accent = pmAccent(t);
                              return GestureDetector(
                                onTap: () {
                                  Haptics.tap();
                                  _selectType(t);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? accent.withOpacity(0.16)
                                        : AppColors.cardFill(context),
                                    border: Border.all(
                                      color: sel
                                          ? accent
                                          : AppColors.cardBorder(context),
                                      width: sel ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        pmIcon(t),
                                        size: 14,
                                        color: sel ? accent : AppColors.textMid,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        t.label,
                                        style: AppTypography.caption.copyWith(
                                          color: sel
                                              ? accent
                                              : AppColors.textSecondary(context),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      emphasised: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: pmAccent(_type).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: pmAccent(_type).withOpacity(0.35),
                              ),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(10),
                            child: _selectedIconSlug != null
                                ? paymentMethodMark(
                                    type: _type,
                                    name: _resolvedName.isEmpty
                                        ? _type.label
                                        : _resolvedName,
                                    iconSlug: _selectedIconSlug,
                                    size: 28,
                                    fallbackColor: pmAccent(_type),
                                  )
                                : Icon(
                                    pmIcon(_type),
                                    size: 28,
                                    color: pmAccent(_type),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _resolvedName.isEmpty
                                      ? _type.label
                                      : _resolvedName,
                                  style: AppTypography.cardTitle
                                      .copyWith(color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _typeSummary,
                                  style: AppTypography.caption
                                      .copyWith(color: subColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_brandOptionsForType(_type).isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _label('Brand', context),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final option in _brandOptionsForType(_type))
                            _PaymentBrandChip(
                              option: option,
                              type: _type,
                              selected: _selectedIconSlug == option.slug,
                              onTap: () {
                                Haptics.tap();
                                setState(() => _selectedIconSlug = option.slug);
                              },
                            ),
                        ],
                      ),
                    ],
                    if (_showsNameField) ...[
                      const SizedBox(height: 18),
                      _label(_nameLabel, context),
                      _textField(
                        controller: _nameCtl,
                        hint: _nameHint,
                        icon: _type == PaymentMethodType.upi
                            ? LucideIcons.atSign
                            : _type == PaymentMethodType.netBanking
                                ? LucideIcons.building2
                                : LucideIcons.tag,
                        onChanged: () => setState(() {}),
                        context: context,
                      ),
                    ],
                    if (_type.isCard) ...[
                      const SizedBox(height: 18),
                      _label('Last 4 digits', context),
                      _textField(
                        controller: _lastFourCtl,
                        hint: '4182',
                        icon: LucideIcons.hash,
                        onChanged: () => setState(() {}),
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        context: context,
                      ),
                      const SizedBox(height: 18),
                      _label('Expiry', context),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: _mmCtl,
                              hint: 'MM',
                              icon: LucideIcons.calendar,
                              onChanged: () => setState(() {}),
                              maxLength: 2,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              context: context,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _textField(
                              controller: _yyCtl,
                              hint: 'YY',
                              icon: LucideIcons.calendar,
                              onChanged: () => setState(() {}),
                              maxLength: 2,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              context: context,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_showsNotesField) ...[
                      const SizedBox(height: 18),
                      _label('Comments', context),
                      _textField(
                        controller: _notesCtl,
                        hint:
                            'Shared account, family wallet, office reimbursement...',
                        icon: LucideIcons.messageSquare,
                        onChanged: () => setState(() {}),
                        context: context,
                      ),
                    ],
                    const SizedBox(height: 18),
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.star,
                            size: 16,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Set as default',
                            style: AppTypography.body
                                .copyWith(color: textColor),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isDefault,
                            onChanged: (v) {
                              Haptics.tap();
                              setState(() => _isDefault = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    NeoButton(
                      label: 'Add payment method',
                      leading: LucideIcons.plus,
                      onPressed: _canSave ? _save : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String s, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          s,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary(context),
            letterSpacing: 1.0,
          ),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required VoidCallback onChanged,
    required BuildContext context,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary(context)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              maxLength: maxLength,
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimary(context)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.body
                    .copyWith(color: AppColors.textTertiary(context)),
                border: InputBorder.none,
                isDense: true,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              cursorColor: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBrandOption {
  final String slug;
  final String label;
  const _PaymentBrandOption(this.slug, this.label);
}

class _PaymentBrandChip extends StatelessWidget {
  final _PaymentBrandOption option;
  final PaymentMethodType type;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentBrandChip({
    required this.option,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = pmAccent(type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(0.16)
              : AppColors.cardFill(context),
          border: Border.all(
            color: selected ? accent : AppColors.cardBorder(context),
            width: selected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: paymentMethodMark(
                type: type,
                name: option.label,
                iconSlug: option.slug,
                size: 18,
                fallbackColor: selected ? accent : AppColors.textMid,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              option.label,
              style: AppTypography.caption.copyWith(
                color: selected ? accent : AppColors.textSecondary(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
