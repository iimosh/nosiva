import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../listings/data/listings_repository.dart';
import '../../listings/domain/listing.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../domain/profile.dart';
import 'current_profile_provider.dart';

final myListingsProvider = FutureProvider<List<Listing>>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  if (profile == null) return Future.value(const []);
  return ref.watch(listingsRepositoryProvider).fetchBySeller(profile.id);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Orders',
            onPressed: () => context.push(AppRoutes.orders),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            tooltip: 'Cart',
            onPressed: () => context.push(AppRoutes.cart),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'design') context.push(AppRoutes.designSystem);
              if (v == 'signout') {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'design', child: Text('Design system ✨')),
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.hotPink)),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (profile) {
          if (profile == null) {
            return const EmptyStateView(title: 'No profile found');
          }
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myListings = ref.watch(myListingsProvider);

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
                  Text(profile.nameOrHandle, style: theme.textTheme.headlineSmall),
                  Text(profile.handle, style: theme.textTheme.bodyMedium),
                  if (profile.location != null)
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14),
                        const SizedBox(width: 2),
                        Text(profile.location!, style: theme.textTheme.bodySmall),
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
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit profile'),
          // TODO: build edit profile screen
          onPressed: () => context.showSnack('Edit profile — TODO ✏️'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('My closet', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        myListings.when(
          loading: () => const SizedBox(height: 200, child: ListingGridSkeleton(itemCount: 2)),
          error: (e, _) => ErrorStateView(message: '$e'),
          data: (listings) {
            if (listings.isEmpty) {
              return const EmptyStateView(
                emoji: '🧺',
                title: 'Your closet is empty bestie ✨',
                message: 'List your first piece and start earning.',
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
              itemCount: listings.length,
              itemBuilder: (_, i) => ListingCard(listing: listings[i]),
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
