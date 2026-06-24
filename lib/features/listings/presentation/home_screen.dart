import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../profile/domain/profile.dart';
import '../../profile/presentation/user_profile_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/listing_enums.dart';
import '../domain/listing_filter.dart';
import '../domain/listing_l10n.dart';
import 'controllers/feed_controller.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/listing_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  void _setQuery(String q) {
    final f = ref.read(feedFilterProvider);
    ref.read(feedFilterProvider.notifier).state = f.copyWith(query: q);
  }

  Future<void> _openFilters() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const FilterSheet(),
  );

  int _countFilters(ListingFilter f) {
    var n = 0;
    if (f.category != null) n++;
    if (f.size != null) n++;
    if (f.condition != null) n++;
    if (f.minPrice != null || f.maxPrice != null) n++;
    if (f.location != null && f.location!.isNotEmpty) n++;
    if (f.styleTags.isNotEmpty) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider);
    final filter = ref.watch(feedFilterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final activeFilters = _countFilters(filter);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: AppSpacing.md,
          title: Text(
            'Nosiva',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.berry,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              tooltip: context.l10n.toggleTheme,
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            ),
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: context.l10n.cart,
              onPressed: () => context.push(AppRoutes.cart),
            ),
            IconButton(
              tooltip: context.l10n.favorites,
              icon: const Icon(Icons.favorite_border_rounded),
              onPressed: () => context.push(AppRoutes.favorites),
            ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  tooltip: context.l10n.filters,
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _openFilters,
                ),
                if (activeFilters > 0)
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.hotPink,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeFilters',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          bottom: TabBar(
            labelColor: AppColors.hotPink,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: AppColors.hotPink,
            tabs: [
              Tab(text: context.l10n.forYou),
              Tab(text: context.l10n.following),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              color: AppColors.hotPink,
              onRefresh: () =>
                  ref.read(feedControllerProvider.notifier).refresh(),
              child: feed.when(
                loading: () => _ForYouScrollView(
                  controller: _scroll,
                  search: _search,
                  filter: filter,
                  activeFilters: activeFilters,
                  onQuery: _setQuery,
                  onCategory: (cat) {
                    final notifier = ref.read(feedFilterProvider.notifier);
                    notifier.state = filter.category == cat
                        ? filter.copyWith(clearCategory: true)
                        : filter.copyWith(category: cat);
                  },
                  sliver: const SliverFillRemaining(
                    child: ListingGridSkeleton(),
                  ),
                ),
                error: (e, _) => _ForYouScrollView(
                  controller: _scroll,
                  search: _search,
                  filter: filter,
                  activeFilters: activeFilters,
                  onQuery: _setQuery,
                  onCategory: (cat) {
                    final notifier = ref.read(feedFilterProvider.notifier);
                    notifier.state = filter.category == cat
                        ? filter.copyWith(clearCategory: true)
                        : filter.copyWith(category: cat);
                  },
                  sliver: SliverFillRemaining(
                    child: ErrorStateView(
                      message: '$e',
                      onRetry: () => ref
                          .read(feedControllerProvider.notifier)
                          .refresh(),
                    ),
                  ),
                ),
                data: (listings) {
                  return _ForYouScrollView(
                    controller: _scroll,
                    search: _search,
                    filter: filter,
                    activeFilters: activeFilters,
                    onQuery: _setQuery,
                    onCategory: (cat) {
                      final notifier = ref.read(feedFilterProvider.notifier);
                      notifier.state = filter.category == cat
                          ? filter.copyWith(clearCategory: true)
                          : filter.copyWith(category: cat);
                    },
                    sliver: listings.isEmpty
                        ? SliverFillRemaining(
                            child: EmptyStateView(
                              icon: Icons.inventory_2_outlined,
                              title: context.l10n.nothingHereYet,
                              message: context.l10n.nothingHereYetMessage,
                            ),
                          )
                        : SliverPadding(
                            padding: AppSpacing.screen,
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisSpacing: AppSpacing.md,
                                childAspectRatio: 0.54,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => ListingCard(listing: listings[i]),
                                childCount: listings.length,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
            const _FollowingFeed(),
          ],
        ),
        floatingActionButton: activeFilters > 0
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.plum,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.clear_rounded),
                label: Text(context.l10n.clearFilters),
                onPressed: () => ref.read(feedFilterProvider.notifier).state =
                    ListingFilter(query: filter.query),
              )
            : null,
      ),
    );
  }
}

class _ForYouScrollView extends StatelessWidget {
  const _ForYouScrollView({
    required this.controller,
    required this.search,
    required this.filter,
    required this.activeFilters,
    required this.onQuery,
    required this.onCategory,
    required this.sliver,
  });

  final ScrollController controller;
  final TextEditingController search;
  final ListingFilter filter;
  final int activeFilters;
  final ValueChanged<String> onQuery;
  final ValueChanged<ListingCategory> onCategory;
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: NosivaTextField(
              hint: context.l10n.homeSearchHint,
              controller: search,
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onSubmitted: onQuery,
              onChanged: (v) {
                if (v.isEmpty) onQuery('');
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _CategoryBar(
            selected: filter.category,
            onSelect: onCategory,
          ),
        ),
        SliverToBoxAdapter(child: _PeopleRail(query: filter.query ?? '')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Text(
                  filter.query?.isNotEmpty == true
                      ? context.l10n.browseItems
                      : context.l10n.latestListings,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: AppColors.plum),
                ),
                const Spacer(),
                if (activeFilters > 0)
                  Text(
                    '$activeFilters ${context.l10n.filters.toLowerCase()}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
        sliver,
      ],
    );
  }
}

class _FollowingFeed extends ConsumerWidget {
  const _FollowingFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(followingFeedProvider);
    return RefreshIndicator(
      color: AppColors.hotPink,
      onRefresh: () async => ref.invalidate(followingFeedProvider),
      child: feed.when(
        loading: () => const ListingGridSkeleton(),
        error: (e, _) => ErrorStateView(
          message: '$e',
          onRetry: () => ref.invalidate(followingFeedProvider),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                EmptyStateView(
                  icon: Icons.group_outlined,
                  title: context.l10n.nothingHereYet,
                  message: context.l10n.nothingHereYetMessage,
                ),
              ],
            );
          }
          return GridView.builder(
            padding: AppSpacing.screen,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.54,
            ),
            itemCount: listings.length,
            itemBuilder: (_, i) => ListingCard(listing: listings[i]),
          );
        },
      ),
    );
  }
}

class _PeopleRail extends ConsumerWidget {
  const _PeopleRail({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.trim().isEmpty) return const SizedBox.shrink();
    final people =
        ref.watch(peopleSearchProvider(query)).valueOrNull ?? const [];
    if (people.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            0,
          ),
          child: Text(
            context.l10n.people,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: people.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) => _PersonCard(person: people[i]),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person});
  final Profile person;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.userPath(person.id)),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.blush,
              backgroundImage: person.avatarUrl != null
                  ? CachedNetworkImageProvider(person.avatarUrl!)
                  : null,
              child: person.avatarUrl == null
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.hotPink,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              person.nameOrHandle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
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
