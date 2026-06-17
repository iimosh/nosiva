import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/listings_repository.dart';
import '../../domain/listing.dart';
import '../../domain/listing_filter.dart';

/// The active filter for the home/browse feed.
final feedFilterProvider =
    StateProvider<ListingFilter>((ref) => const ListingFilter());

/// Paginated, filterable feed with infinite scroll.
class FeedController extends AsyncNotifier<List<Listing>> {
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<Listing>> build() async {
    final filter = ref.watch(feedFilterProvider);
    _page = 0;
    _hasMore = true;
    final repo = ref.watch(listingsRepositoryProvider);
    final first = await repo.fetchFeed(filter: filter, page: 0);
    _hasMore = first.length == ListingsRepository.pageSize;
    return first;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    final filter = ref.read(feedFilterProvider);
    final repo = ref.read(listingsRepositoryProvider);
    try {
      final next = await repo.fetchFeed(filter: filter, page: _page + 1);
      _page += 1;
      _hasMore = next.length == ListingsRepository.pageSize;
      final current = state.valueOrNull ?? const [];
      state = AsyncValue.data([...current, ...next]);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final feedControllerProvider =
    AsyncNotifierProvider<FeedController, List<Listing>>(FeedController.new);
