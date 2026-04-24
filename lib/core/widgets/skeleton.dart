import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Shimmer block — drops in for loading state. No spinners, ever.
class Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 4,
  });

  const Skeleton.circle({super.key, required this.width})
      : height = width,
        radius = 999;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.glassFill,
      highlightColor: AppColors.glassFillHi,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Shimmering list placeholder — used before data arrives.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const SkeletonList({
    super.key,
    this.count = 6,
    this.itemHeight = 84,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Skeleton(
        width: double.infinity,
        height: itemHeight,
        radius: 14,
      ),
    );
  }
}
