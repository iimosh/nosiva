import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../../profile/domain/profile.dart';
import '../../profile/presentation/user_profile_screen.dart';
import '../data/reviews_repository.dart';
import '../domain/review.dart';
import 'widgets/star_rating.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/widgets/pull_to_refresh.dart';

class ReviewsListScreen extends ConsumerWidget {
  const ReviewsListScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(userId)).valueOrNull;
    final reviews = ref.watch(userReviewsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(profile?.nameOrHandle ?? context.l10n.reviews),
      ),
      body: PullToRefresh(
        onRefresh: () => Future.wait([
          ref.refresh(userReviewsProvider(userId).future),
          ref.refresh(userProfileProvider(userId).future),
        ]),
        child: reviews.when(
          loading: () => const ListSkeleton(lines: 3),
          error: (e, _) => ErrorStateView(
            message: friendlyError(context.l10n, e),
            onRetry: () => ref.invalidate(userReviewsProvider(userId)),
          ),
          data: (list) {
            if (list.isEmpty) {
              return EmptyStateView(
                icon: Icons.star_outline_rounded,
                title: context.l10n.noReviewsYet,
                message: context.l10n.noReviewsYetMessage,
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: list.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                if (i == 0) return _RatingSummary(profile: profile);
                return _ReviewCard(review: list[i - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(p.ratingAvg.toStringAsFixed(1), style: theme.textTheme.headlineMedium),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              StarRating(rating: p.ratingAvg.round(), size: 16),
              Text(context.l10n.ratingCount(p.ratingCount),
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewer = review.reviewer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.palette.placeholder,
                backgroundImage: reviewer?.avatarUrl != null
                    ? CachedNetworkImageProvider(reviewer!.avatarUrl!)
                    : null,
                child: reviewer?.avatarUrl == null
                    ? const Icon(Icons.person_outline_rounded,
                        color: AppColors.hotPink, size: 18)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  reviewer?.nameOrHandle ?? context.l10n.nosivaUser,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (review.createdAt != null)
                Text(Formatters.timeAgo(review.createdAt!, context.l10n),
                    style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          StarRating(rating: review.rating, size: 16),
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(review.comment!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
