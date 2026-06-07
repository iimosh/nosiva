import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Pink-tinted shimmer skeleton primitive.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadii.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surfaceMutedDark : AppColors.blush,
      highlightColor:
          isDark ? AppColors.surfaceDark : AppColors.cream,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// A grid of shimmer cards mimicking the listing feed while it loads.
class ListingGridSkeleton extends StatelessWidget {
  const ListingGridSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppSpacing.screen,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.62,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(child: ShimmerBox(height: double.infinity, radius: AppRadii.xl)),
          SizedBox(height: AppSpacing.xs),
          ShimmerBox(width: 120, height: 14),
          SizedBox(height: 6),
          ShimmerBox(width: 70, height: 12),
        ],
      ),
    );
  }
}
