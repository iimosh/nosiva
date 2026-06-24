import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/heart_button.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../domain/listing.dart';

/// A listing tile for the feed grid. Heart toggles optimistically.
class ListingCard extends ConsumerWidget {
  const ListingCard({super.key, required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favs = ref.watch(favoritesControllerProvider).valueOrNull ?? const {};
    final liked = favs.contains(listing.id) || listing.isFavorited;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.listingDetailPath(listing.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: AppRadii.card,
                  child: _Image(url: listing.coverImageUrl),
                ),
                if (listing.isSold)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: AppRadii.card,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.45),
                        child: Center(
                          child: Text(context.l10n.sold.toUpperCase(),
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: HeartButton(
                    liked: liked,
                    size: 18,
                    onTap: () async {
                      try {
                        await ref
                            .read(favoritesControllerProvider.notifier)
                            .toggle(listing.id);
                        if (context.mounted && !liked) {
                          context.showSuccess('Snatched! Added to favorites 💖');
                        }
                      } catch (_) {
                        if (context.mounted) {
                          context.showError('Couldn’t update favorites');
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Formatters.price(listing.price),
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.hotPink),
          ),
          Text(
            listing.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            [listing.brand, listing.size].whereType<String>().join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Image extends StatelessWidget {
  const _Image({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.blush,
        alignment: Alignment.center,
        child: const Text('👗', style: TextStyle(fontSize: 36)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(color: AppColors.blush),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.blush,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: AppColors.plumFaint),
      ),
    );
  }
}
