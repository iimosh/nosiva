import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/widgets/state_views.dart';
import '../../listings/domain/listing.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../data/favorites_repository.dart';
import 'favorites_controller.dart';

/// The user's saved items. Rebuilds when favorites are toggled anywhere.
final favoriteListingsProvider = FutureProvider<List<Listing>>((ref) {
  ref.watch(favoritesControllerProvider); // refetch when the set changes
  return ref.watch(favoritesRepositoryProvider).fetchFavoriteListings();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoriteListingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.favorites)),
      body: favs.when(
        loading: () => const ListingGridSkeleton(),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (listings) {
          if (listings.isEmpty) {
            return EmptyStateView(
              emoji: '💝',
              title: context.l10n.wishlistEmpty,
              message: context.l10n.wishlistEmptyMessage,
            );
          }
          return GridView.builder(
            padding: AppSpacing.screen,
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
    );
  }
}
