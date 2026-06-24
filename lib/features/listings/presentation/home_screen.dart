import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/listing_enums.dart';
import '../domain/listing_l10n.dart';
import 'controllers/feed_controller.dart';
import 'widgets/listing_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider);
    final filter = ref.watch(feedFilterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          'Nosiva',
          style: GoogleFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.hotPink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.toggleTheme,
            icon: Icon(themeMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () => context.push(AppRoutes.favorites),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          _CategoryBar(
            selected: filter.category,
            onSelect: (cat) {
              final notifier = ref.read(feedFilterProvider.notifier);
              notifier.state = filter.category == cat
                  ? filter.copyWith(clearCategory: true)
                  : filter.copyWith(category: cat);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.hotPink,
              onRefresh: () =>
                  ref.read(feedControllerProvider.notifier).refresh(),
              child: feed.when(
                loading: () => const ListingGridSkeleton(),
                error: (e, _) => ErrorStateView(
                  message: '$e',
                  onRetry: () =>
                      ref.read(feedControllerProvider.notifier).refresh(),
                ),
                data: (listings) {
                  if (listings.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        EmptyStateView(
                          emoji: '🛍️',
                          title: context.l10n.nothingHereYet,
                          message: context.l10n.nothingHereYetMessage,
                        ),
                      ],
                    );
                  }
                  return GridView.builder(
                    controller: _scroll,
                    padding: AppSpacing.screen,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelect});

  final ListingCategory? selected;
  final ValueChanged<ListingCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: ListingCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) {
          final cat = ListingCategory.values[i];
          return Center(
            child: NosivaChip(
              label: cat.localizedWithEmoji(context.l10n),
              selected: selected == cat,
              onTap: () => onSelect(cat),
            ),
          );
        },
      ),
    );
  }
}
