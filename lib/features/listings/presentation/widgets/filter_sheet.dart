import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/location/location_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/listing_enums.dart';
import '../domain/listing_filter.dart';
import 'controllers/feed_controller.dart';
import 'widgets/listing_card.dart';

/// Full-text search + filters. Drives the shared [feedFilterProvider] so
/// results reuse the paginated feed query.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    final f = ref.read(feedFilterProvider);
    ref.read(feedFilterProvider.notifier).state = f.copyWith(query: q);
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider);
    final filter = ref.watch(feedFilterProvider);
    final activeFilters = _countFilters(filter);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: NosivaTextField(
          hint: 'Search for that dream piece…',
          controller: _controller,
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onChanged: (v) {
            if (v.isEmpty) _search('');
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: const SizedBox(height: 8),
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
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
                      style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
        ],
      ),
      body: feed.when(
        loading: () => const ListingGridSkeleton(),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (listings) {
          if (listings.isEmpty) {
            return const EmptyStateView(
              emoji: '🔍',
              title: 'No matches, bestie',
              message: 'Try fewer filters or a different search.',
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
      floatingActionButton: activeFilters > 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.hotPink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Clear filters'),
              onPressed: () => ref.read(feedFilterProvider.notifier).state =
                  ListingFilter(query: filter.query),
            )
          : null,
    );
  }

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
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ListingFilter _draft = ref.read(feedFilterProvider);
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _location = TextEditingController();
  bool _detectingLocation = false;

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      _location.text = await ref.read(locationServiceProvider).currentCity();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _min.text = _draft.minPrice?.toStringAsFixed(0) ?? '';
    _max.text = _draft.maxPrice?.toStringAsFixed(0) ?? '';
    _location.text = _draft.location ?? '';
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _location.dispose();
    super.dispose();
  }

  void _apply() {
    final styles = _draft.styleTags;
    final location = _location.text.trim();
    ref.read(feedFilterProvider.notifier).state = _draft.copyWith(
      minPrice: _min.text.isEmpty ? null : double.tryParse(_min.text),
      maxPrice: _max.text.isEmpty ? null : double.tryParse(_max.text),
      location: location.isEmpty ? null : location,
      clearMinPrice: _min.text.isEmpty,
      clearMaxPrice: _max.text.isEmpty,
      clearLocation: location.isEmpty,
      styleTags: styles,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Filters', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Text('Category', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in ListingCategory.values)
                NosivaChip(
                  label: '${c.emoji} ${c.label}',
                  selected: _draft.category == c,
                  onTap: () => setState(() => _draft = _draft.category == c
                      ? _draft.copyWith(clearCategory: true)
                      : _draft.copyWith(category: c)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Condition', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in ItemCondition.values)
                NosivaChip(
                  label: c.label,
                  selected: _draft.condition == c,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(condition: c)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Size', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in kSizes)
                NosivaChip(
                  label: s,
                  selected: _draft.size == s,
                  onTap: () => setState(() => _draft = _draft.copyWith(size: s)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Style', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in kStyleTags)
                NosivaChip(
                  label: tag,
                  selected: _draft.styleTags.contains(tag),
                  onTap: () => setState(() {
                    final next = [..._draft.styleTags];
                    next.contains(tag) ? next.remove(tag) : next.add(tag);
                    _draft = _draft.copyWith(styleTags: next);
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Location', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          NosivaTextField(
            hint: 'City or country',
            controller: _location,
            prefixIcon: Icons.place_outlined,
            suffixIcon: _detectingLocation
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.hotPink),
                    ),
                  )
                : IconButton(
                    tooltip: 'Use my location',
                    icon: const Icon(Icons.my_location_rounded,
                        color: AppColors.hotPink),
                    onPressed: _detectLocation,
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Price range', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: NosivaTextField(
                  hint: 'Min',
                  controller: _min,
                  keyboardType: TextInputType.number,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text('—'),
              ),
              Expanded(
                child: NosivaTextField(
                  hint: 'Max',
                  controller: _max,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          NosivaButton(
            label: 'Show results',
            variant: NosivaButtonVariant.gradient,
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}
