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
import '../../../auth/presentation/guest_prompt.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../domain/listing.dart';
import '../../domain/listing_enums.dart';
import '../../domain/listing_l10n.dart';
import '../../../../core/theme/app_palette.dart';

class ListingCard extends ConsumerWidget {
  const ListingCard({super.key, required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favs = ref.watch(favoritesControllerProvider).valueOrNull ?? const {};
    final liked = favs.contains(listing.id) || listing.isFavorited;
    final meta = [
      listing.brand,
      listing.size == null ? null : '${context.l10n.size} ${listing.size}',
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' - ');

    // Photo-first card: a large rounded image with the details underneath,
    // no box around it.
    return InkWell(
      onTap: () => context.push(AppRoutes.listingDetailPath(listing.id)),
      borderRadius: AppRadii.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadii.tile,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Image(url: listing.coverImageUrl),
                  const _ImageShade(),
                  if (listing.isSold)
                    Positioned.fill(
                      child: ColoredBox(
                        color: theme.colorScheme.surface.withValues(alpha: 0.55),
                      ),
                    ),
                  if (listing.statusEnum != ListingStatus.active)
                    Positioned(
                      left: AppSpacing.xs,
                      top: AppSpacing.xs,
                      child: _StatusBadge(label: _statusLabel(context)),
                    ),
                  Positioned(
                    right: AppSpacing.xs,
                    top: AppSpacing.xs,
                    child: _FavoriteControl(
                      liked: liked,
                      onTap: () => _toggleFavorite(context, ref, liked),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, AppSpacing.xs, 2, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.price(listing.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 1),
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  meta.isEmpty
                      ? listing.categoryEnum.localizedLabel(context.l10n)
                      : meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                _CardFooter(listing: listing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context) =>
      listing.statusEnum.localizedLabel(context.l10n).toUpperCase();

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    bool liked,
  ) async {
    if (!ensureSignedIn(context, ref, GuestAction.favorite)) return;
    try {
      await ref.read(favoritesControllerProvider.notifier).toggle(listing.id);
      if (context.mounted && !liked) {
        context.showSuccess(context.l10n.favoriteAdded);
      }
    } catch (_) {
      if (context.mounted) {
        context.showError(context.l10n.favoriteUpdateFailed);
      }
    }
  }
}

class _FavoriteControl extends StatelessWidget {
  const _FavoriteControl({required this.liked, required this.onTap});

  final bool liked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        boxShadow: AppShadows.subtle(AppColors.plum),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: HeartButton(
          liked: liked,
          size: 18,
          withBackground: false,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.berry.withValues(alpha: 0.92),
        borderRadius: AppRadii.chip,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = listing.location?.trim();

    return Row(
      children: [
        if (location != null && location.isNotEmpty) ...[
          Icon(
            Icons.place_outlined,
            size: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ] else
          const Spacer(),
        if (listing.favoriteCount > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.favorite_border_rounded,
            size: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text('${listing.favoriteCount}', style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _ImageShade extends StatelessWidget {
  const _ImageShade();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x1A000000),
            Color(0x00000000),
            Color(0x12000000),
          ],
        ),
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
        color: context.palette.placeholder,
        alignment: Alignment.center,
        child: const Icon(
          Icons.checkroom_outlined,
          color: AppColors.hotPink,
          size: 38,
        ),
      );
    }
    // Decode the photo at the size the card actually shows it, not the
    // uploaded 1600 px — far less memory and smoother scrolling. Sized by
    // height: the photo area is taller than wide, so square and portrait
    // photos still fill it without being stretched.
    return LayoutBuilder(
      builder: (context, box) {
        final px = box.maxHeight.isFinite
            ? (box.maxHeight * MediaQuery.devicePixelRatioOf(context)).round()
            : null;
        return CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          memCacheHeight: px,
          placeholder: (_, __) => ColoredBox(color: context.palette.placeholder),
          errorWidget: (_, __, ___) => Container(
            color: context.palette.placeholder,
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: context.palette.onPlaceholder,
            ),
          ),
        );
      },
    );
  }
}
