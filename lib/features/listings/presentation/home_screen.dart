import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          'Nosiva',
          style: theme.textTheme.headlineMedium
              ?.copyWith(color: AppColors.hotPink, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(themeMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            tooltip: 'Favorites',
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () => context.push(AppRoutes.favorites),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                tooltip: 'Filters',
                icon: const Icon(Icons.tune_rounded),
                onPressed: _openFilters,
              ),
              if (activeFilters > 0)
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.hotPink, shape: BoxShape.circle),
                  child: Text('$activeFilters',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
            child: NosivaTextField(
              hint: 'Search items & people…',
              controller: _search,
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onSubmitted: _setQuery,
              onChanged: (v) {
                if (v.isEmpty) _setQuery('');
              },
            ),
          ),
          _CategoryBar(
            selected: filter.category,
            onSelect: (cat) {
              final notifier = ref.read(feedFilterProvider.notifier);
              notifier.state = filter.category == cat
                  ? filter.copyWith(clearCategory: true)
                  : filter.copyWith(category: cat);
            },
          ),
          _PeopleRail(query: filter.query ?? ''),
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
                      children: const [
                        SizedBox(height: 80),
                        EmptyStateView(
                          emoji: '🛍️',
                          title: 'Nothing here yet',
                          message:
                              'Try a different search or filter, or check back soon ✨',
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
      floatingActionButton: activeFilters > 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.plum,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Clear filters'),
              onPressed: () => ref.read(feedFilterProvider.notifier).state =
                  ListingFilter(query: filter.query),
            )
          : null,
    );
  }
}

class _PeopleRail extends ConsumerWidget {
  const _PeopleRail({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.trim().isEmpty) return const SizedBox.shrink();
    final people = ref.watch(peopleSearchProvider(query)).valueOrNull ?? const [];
    if (people.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
          child: Text('People',
              style: Theme.of(context).textTheme.titleMedium),
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
                  ? const Text('💁‍♀️', style: TextStyle(fontSize: 22))
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
              label: '${cat.emoji} ${cat.label}',
              selected: selected == cat,
              onTap: () => onSelect(cat),
            ),
          );
        },
      ),
    );
  }
}
