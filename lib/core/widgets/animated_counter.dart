import 'package:flutter/material.dart';

import '../models/billing_cycle.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/currency.dart';

/// Animated currency counter — counts up on first appearance.
/// Used on dashboard hero numbers.
class AnimatedCurrency extends StatefulWidget {
  final double value;
  final String currency;
  final BillingCycle? cycle;
  final TextStyle? style;
  final Color? color;
  final Duration duration;
  final bool compact;
  const AnimatedCurrency({
    super.key,
    required this.value,
    required this.currency,
    this.cycle,
    this.style,
    this.color,
    this.duration = const Duration(milliseconds: 900),
    this.compact = false,
  });

  @override
  State<AnimatedCurrency> createState() => _AnimatedCurrencyState();
}

class _AnimatedCurrencyState extends State<AnimatedCurrency>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late Animation<double> _anim;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _anim = Tween<double>(begin: _from, end: widget.value)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void didUpdateWidget(covariant AnimatedCurrency old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _anim.value;
      _anim = Tween<double>(begin: _from, end: widget.value)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(_ctrl);
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style ?? AppTypography.bigNumber;
    final clr = widget.color ?? AppColors.textHi;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final current = _anim.value;
        final text = widget.cycle != null
            ? CurrencyUtil.formatContextual(
                current,
                code: widget.currency,
                cycle: widget.cycle!,
              )
            : CurrencyUtil.formatAmount(
                current,
                code: widget.currency,
                compact: widget.compact,
                decimals: widget.currency == 'INR' ? 0 : 2,
              );
        return Text(text, style: base.copyWith(color: clr));
      },
    );
  }
}

/// Plain integer counter.
class AnimatedCount extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Color? color;
  final Duration duration;
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.color,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, duration: widget.duration,
  )..forward();

  late Animation<double> _anim =
      Tween<double>(begin: 0, end: widget.value.toDouble())
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(_ctrl);

  @override
  void didUpdateWidget(covariant AnimatedCount old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(begin: _anim.value, end: widget.value.toDouble())
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(_ctrl);
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style ?? AppTypography.bigNumber;
    final clr = widget.color ?? AppColors.textHi;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        _anim.value.round().toString(),
        style: base.copyWith(color: clr),
      ),
    );
  }
}
