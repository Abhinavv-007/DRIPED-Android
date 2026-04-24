import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Standard drag handle used on bottom sheets.
class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.glassBorderHi,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
