import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

// Skeleton loading screens: grey outlines shaped like the content that's on
// its way, with one shimmer wave passing over the whole screen. They feel
// faster than a spinner and keep the layout from jumping when data arrives.
//
// Build a skeleton from [Bone]s inside one [SkeletonShimmer], so every piece
// shimmers in step.

/// Runs a single shimmer over everything inside it.
class SkeletonShimmer extends StatelessWidget {
  const SkeletonShimmer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
      highlightColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: child,
    );
  }
}

/// One placeholder shape. Only meaningful inside a [SkeletonShimmer].
class Bone extends StatelessWidget {
  const Bone({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadii.sm,
  });

  const Bone.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = AppRadii.pill;

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // The shimmer paints over white; the actual colour comes from it.
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A single shimmering shape, for one-off use.
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
  Widget build(BuildContext context) => SkeletonShimmer(
        child: Bone(width: width, height: height, radius: radius),
      );
}

/// The listing feed: photo cards with price, title and details underneath.
class ListingGridSkeleton extends StatelessWidget {
  const ListingGridSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: GridView.builder(
        padding: AppSpacing.screen,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.54,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => const _CardBones(),
      ),
    );
  }
}

class _CardBones extends StatelessWidget {
  const _CardBones();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Bone(height: double.infinity, radius: AppRadii.xl)),
        SizedBox(height: AppSpacing.xs),
        Bone(width: 70, height: 16),
        SizedBox(height: 6),
        Bone(width: 120, height: 12),
        SizedBox(height: 6),
        Bone(width: 90, height: 10),
      ],
    );
  }
}

enum SkeletonLeading { none, circle, square }

/// Rows of an avatar or thumbnail with lines of text — inbox, orders,
/// followers, reviews, admin lists.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    this.itemCount = 8,
    this.leading = SkeletonLeading.circle,
    this.leadingSize = 48,
    this.lines = 2,
  });

  final int itemCount;
  final SkeletonLeading leading;
  final double leadingSize;
  final int lines;

  // Varied widths look like real text rather than a barcode.
  static const _widths = [0.55, 0.8, 0.4, 0.7, 0.5, 0.85, 0.45, 0.65];

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => Row(
          children: [
            if (leading == SkeletonLeading.circle)
              Bone.circle(size: leadingSize)
            else if (leading == SkeletonLeading.square)
              Bone(width: leadingSize, height: leadingSize, radius: AppRadii.md),
            if (leading != SkeletonLeading.none)
              const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var line = 0; line < lines; line++) ...[
                    if (line > 0) const SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: line == 0
                          ? _widths[i % _widths.length]
                          : _widths[(i + line * 3) % _widths.length],
                      child: Bone(height: line == 0 ? 14 : 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A listing page: big photo, price, title, details and description.
class ListingDetailSkeleton extends StatelessWidget {
  const ListingDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          const Bone(height: 440, radius: 0),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Bone(width: 130, height: 30),
                    Spacer(),
                    Bone(width: 72, height: 26, radius: AppRadii.pill),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Bone(width: 220, height: 20),
                const SizedBox(height: AppSpacing.sm),
                const Bone(width: 170, height: 12),
                const SizedBox(height: AppSpacing.lg),
                for (var i = 0; i < 3; i++) ...[
                  const Row(
                    children: [
                      Bone(width: 90, height: 14),
                      Spacer(),
                      Bone(width: 110, height: 14),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.sm),
                const Bone(height: 12),
                const SizedBox(height: 8),
                const FractionallySizedBox(widthFactor: 0.9, child: Bone(height: 12)),
                const SizedBox(height: 8),
                const FractionallySizedBox(widthFactor: 0.6, child: Bone(height: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A profile: avatar and name, stats, a button, then their listings.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Row(
            children: [
              Bone.circle(size: 80),
              SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone(width: 160, height: 20),
                  SizedBox(height: 8),
                  Bone(width: 100, height: 14),
                  SizedBox(height: 6),
                  Bone(width: 80, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < 3; i++)
                const Column(
                  children: [
                    Bone(width: 36, height: 18),
                    SizedBox(height: 6),
                    Bone(width: 64, height: 12),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Bone(height: 48, radius: AppRadii.lg),
          const SizedBox(height: AppSpacing.lg),
          const Bone(width: 120, height: 20),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(child: _CardBones()),
                SizedBox(width: AppSpacing.md),
                Expanded(child: _CardBones()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A conversation: message bubbles on both sides.
class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

  // (mine, width, height) — reads like a real back-and-forth.
  static const _bubbles = [
    (false, 180.0, 40.0),
    (false, 120.0, 40.0),
    (true, 220.0, 56.0),
    (false, 150.0, 40.0),
    (true, 90.0, 40.0),
    (true, 200.0, 72.0),
    (false, 160.0, 40.0),
  ];

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final (mine, width, height) in _bubbles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Bone(width: width, height: height, radius: 18),
              ),
            ),
        ],
      ),
    );
  }
}

enum FormSkeletonHeader { avatar, photos }

/// An edit form: avatar or photo row, then labelled fields.
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key, this.header = FormSkeletonHeader.avatar});
  final FormSkeletonHeader header;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (header == FormSkeletonHeader.avatar)
            const Center(child: Bone.circle(size: 104))
          else
            const Row(
              children: [
                Bone(width: 96, height: 96, radius: AppRadii.lg),
                SizedBox(width: AppSpacing.sm),
                Bone(width: 96, height: 96, radius: AppRadii.lg),
                SizedBox(width: AppSpacing.sm),
                Bone(width: 96, height: 96, radius: AppRadii.lg),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < 5; i++) ...[
            const Bone(width: 90, height: 12),
            const SizedBox(height: AppSpacing.xs),
            const Bone(height: 52, radius: AppRadii.lg),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

/// A detail page made of cards: item summary on top, then sections.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Row(
            children: [
              Bone(width: 72, height: 72, radius: AppRadii.lg),
              SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone(width: 160, height: 16),
                  SizedBox(height: 8),
                  Bone(width: 90, height: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < 4; i++) ...[
            const Bone(height: 64, radius: AppRadii.lg),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
