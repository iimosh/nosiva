import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/return_after_sign_in.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../listings/data/listings_repository.dart';
import '../../listings/domain/listing_filter.dart';

/// Cover photos of the newest listings, for the welcome collage. Listings
/// are public, so this works before anyone signs in.
final _showcaseProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final listings = await ref
      .watch(listingsRepositoryProvider)
      .fetchFeed(filter: const ListingFilter(), page: 0);
  return listings
      .map((l) => l.coverImageUrl)
      .whereType<String>()
      .where((url) => url.isNotEmpty)
      .take(12)
      .toList();
});

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  void _getStarted(BuildContext context, WidgetRef ref) {
    ref.read(welcomeSeenProvider.notifier).markSeen();
    context.go(AppRoutes.home);
  }

  void _signIn(BuildContext context, WidgetRef ref) {
    ref.read(welcomeSeenProvider.notifier).markSeen();
    ref.read(returnAfterSignInProvider).clear();
    context.push(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;
    final photos = ref.watch(_showcaseProvider).valueOrNull ?? const <String>[];
    final collageHeight = MediaQuery.sizeOf(context).height * 0.62;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: collageHeight,
            child: _Collage(photos: photos),
          ),
          // Fade the collage into the page.
          Positioned(
            top: collageHeight * 0.45,
            left: 0,
            right: 0,
            height: collageHeight * 0.55 + 1,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      background.withValues(alpha: 0),
                      background.withValues(alpha: 0.85),
                      background,
                    ],
                    stops: const [0, 0.6, 1],
                  ),
                ),
              ),
            ),
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: _LanguagePill(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.welcomeHeadlineTop,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium,
                    ),
                    Text(
                      context.l10n.welcomeHeadlineAccent,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium
                          ?.copyWith(color: AppColors.hotPink),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _GetStartedButton(onPressed: () => _getStarted(context, ref)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.l10n.haveAccountQuestion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _signIn(context, ref),
                          child: Text(context.l10n.signIn),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      child: Text(
        context.l10n.getStarted.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _LanguagePill extends ConsumerWidget {
  const _LanguagePill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeControllerProvider);
    return PopupMenuButton<String>(
      tooltip: context.l10n.language,
      onSelected: (value) => ref.read(localeControllerProvider.notifier).setLocale(
            value == 'mk' ? LocaleController.macedonian : LocaleController.english,
          ),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'en', child: Text(context.l10n.english)),
        PopupMenuItem(value: 'mk', child: Text(context.l10n.macedonian)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: AppRadii.chip,
          boxShadow: AppShadows.subtle(AppColors.plum),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 18, color: theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              locale.languageCode.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three columns of rounded photo tiles, tilted and slowly drifting in
/// opposite directions.
class _Collage extends StatefulWidget {
  const _Collage({required this.photos});
  final List<String> photos;

  @override
  State<_Collage> createState() => _CollageState();
}

class _CollageState extends State<_Collage> with SingleTickerProviderStateMixin {
  static const _gap = 12.0;
  static const _heights = [
    [150.0, 205.0, 170.0, 190.0],
    [205.0, 160.0, 195.0, 155.0],
    [170.0, 195.0, 150.0, 200.0],
  ];

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 45),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "reduce motion" setting.
    if (MediaQuery.of(context).disableAnimations) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  /// Real photos when there are enough; otherwise photos mixed with styled
  /// placeholder tiles, so the collage never looks empty or repetitive.
  _Tile _tileFor(int slot) {
    final photos = widget.photos;
    if (photos.length >= 6) return _Tile.photo(photos[slot % photos.length], slot);
    if (slot.isOdd && slot ~/ 2 < photos.length) {
      return _Tile.photo(photos[slot ~/ 2], slot);
    }
    return _Tile.placeholder(slot);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.rotate(
          angle: -0.18,
          child: Transform.scale(
            scale: 1.25,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height * 0.62,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var col = 0; col < 3; col++) ...[
                    if (col > 0) const SizedBox(width: _gap),
                    Expanded(
                      child: _DriftingColumn(
                        animation: _drift,
                        reverse: col == 1,
                        heights: _heights[col],
                        gap: _gap,
                        tiles: [for (var i = 0; i < 4; i++) _tileFor(col * 4 + i)],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DriftingColumn extends StatelessWidget {
  const _DriftingColumn({
    required this.animation,
    required this.reverse,
    required this.heights,
    required this.gap,
    required this.tiles,
  });

  final Animation<double> animation;
  final bool reverse;
  final List<double> heights;
  final double gap;
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) {
    // One full set of tiles; drawn twice so the loop is seamless.
    final cycle = heights.fold<double>(0, (sum, h) => sum + h + gap);
    final column = Column(
      children: [
        for (var round = 0; round < 3; round++)
          for (var i = 0; i < tiles.length; i++) ...[
            SizedBox(height: heights[i], child: tiles[i]),
            SizedBox(height: gap),
          ],
      ],
    );

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        child: AnimatedBuilder(
          animation: animation,
          child: column,
          builder: (_, child) {
            final t = reverse ? animation.value : 1 - animation.value;
            return Transform.translate(offset: Offset(0, -cycle * t), child: child);
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile.photo(String this.url, this.slot);
  const _Tile.placeholder(this.slot) : url = null;

  final String? url;
  final int slot;

  static const _icons = [
    Icons.checkroom_outlined,
    Icons.shopping_bag_outlined,
    Icons.diamond_outlined,
    Icons.watch_outlined,
    Icons.dry_cleaning_outlined,
    Icons.local_mall_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColors = dark
        ? [
            AppColors.surfaceMutedDark,
            AppColors.hotPink.withValues(alpha: 0.22),
            AppColors.lilac.withValues(alpha: 0.24),
            AppColors.surfaceDark,
          ]
        : [
            AppColors.blush,
            AppColors.lilac.withValues(alpha: 0.28),
            AppColors.hotPinkSoft.withValues(alpha: 0.55),
            AppColors.surfaceMutedLight,
          ];
    final tint = placeholderColors[slot % placeholderColors.length];

    final placeholder = ColoredBox(
      color: tint,
      child: Center(
        child: Icon(
          _icons[slot % _icons.length],
          size: 40,
          color: (dark ? AppColors.hotPinkSoft : AppColors.berry)
              .withValues(alpha: 0.55),
        ),
      ),
    );

    // The tint always sits underneath, so a tile is never blank while its
    // photo is still downloading.
    return ClipRRect(
      borderRadius: AppRadii.tile,
      child: url == null
          ? placeholder
          : ColoredBox(
              color: tint,
              child: CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                // Tiles are small: decode a reduced copy, not the full photo.
                memCacheWidth: 360,
                fadeInDuration: const Duration(milliseconds: 400),
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => placeholder,
              ),
            ),
    );
  }
}
