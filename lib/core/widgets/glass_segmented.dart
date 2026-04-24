import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/haptics.dart';

class GlassSegmented<T> extends StatelessWidget {
  final List<SegmentedOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;
  const GlassSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        border: Border.all(color: AppColors.glassBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final opt in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Haptics.tap();
                  onChanged(opt.value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: opt.value == selected
                        ? AppColors.gold
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    opt.label,
                    style: AppTypography.caption.copyWith(
                      color: opt.value == selected
                          ? AppColors.ink
                          : AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SegmentedOption<T> {
  final T value;
  final String label;
  const SegmentedOption(this.value, this.label);
}

/// Horizontal pill selector — multi-option, scrolls horizontally.
class GlassPillRow<T> extends StatelessWidget {
  final List<SegmentedOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  const GlassPillRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final o = options[i];
          final sel = o.value == selected;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Haptics.tap();
              onChanged(o.value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? AppColors.gold : AppColors.glassFill,
                border: Border.all(
                    color: sel
                        ? AppColors.gold
                        : AppColors.glassBorder),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                o.label,
                style: AppTypography.caption.copyWith(
                  color: sel ? AppColors.ink : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
