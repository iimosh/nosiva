import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/widgets/state_views.dart';
import '../../listings/presentation/controllers/listing_detail_provider.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

final userProfileProvider = FutureProvider.family<Profile?, String>((ref, id) {
  return ref.watch(profileRepositoryProvider).fetchById(id);
});

final peopleSearchProvider =
    FutureProvider.family<List<Profile>, String>((ref, query) {
  return ref.watch(profileRepositoryProvider).search(query);
});

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.hotPink)),
        error: (e, _) => ErrorStateView(
          message: '$e',
          onRetry: () => ref.invalidate(userProfileProvider(userId)),
        ),
        data: (profile) {
          if (profile == null) {
            return const EmptyStateView(emoji: '👻', title: 'User not found');
          }
          return _Body(profile: profile);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listings = ref.watch(sellerListingsProvider(profile.id));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.blush,
              backgroundImage: profile.avatarUrl != null
                  ? CachedNetworkImageProvider(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? const Text('💁‍♀️', style: TextStyle(fontSize: 32))
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.nameOrHandle,
                      style: theme.textTheme.headlineSmall),
                  Text(profile.handle, style: theme.textTheme.bodyMedium),
                  if (profile.location != null)
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14),
                        const SizedBox(width: 2),
                        Text(profile.location!,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        if (profile.bio != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(profile.bio!, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: 'Followers', value: '${profile.followerCount}'),
            _Stat(label: 'Following', value: '${profile.followingCount}'),
            _Stat(
                label: 'Rating',
                value: '${profile.ratingAvg.toStringAsFixed(1)} ⭐'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // TODO: wire follow/unfollow
        NosivaButton(
          label: 'Follow',
          variant: NosivaButtonVariant.gradient,
          onPressed: () {},
        ),
        if (profile.vibeTags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in profile.vibeTags) NosivaChip(label: '#$tag'),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Listings', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        listings.when(
          loading: () => const SizedBox(
              height: 200, child: ListingGridSkeleton(itemCount: 2)),
          error: (e, _) => ErrorStateView(message: '$e'),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyStateView(
                emoji: '🧺',
                title: 'No listings yet',
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.62,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => ListingCard(listing: items[i]),
            );
          },
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
