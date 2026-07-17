import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/listings_repository.dart';
import '../../domain/listing.dart';
import '../../domain/listing_enums.dart';
import '../../domain/listing_filter.dart';

// autoDispose: without it, once a listing is viewed the fetched copy stays
// cached for the rest of the app session, so reopening it later shows stale
// data (price, status, view count, ...) until the app is restarted. The
// explicit ref.invalidate() calls elsewhere (edit, cart, orders) still work
// the same way on top of this — they force an immediate refetch for a
// still-mounted screen instead of waiting for the next fresh visit.
final listingDetailProvider =
    FutureProvider.autoDispose.family<Listing, String>((ref, id) {
  return ref.watch(listingsRepositoryProvider).fetchById(id);
});

/// One-shot side effect: records a view each time a listing detail screen is
/// opened. autoDispose means the provider is torn down when the screen is
/// left, so reopening the same listing later starts a fresh instance (and
/// records another view) — while rebuilds within a single visit (e.g. after
/// favoriting) reuse the same cached instance and don't double-count.
final listingViewTrackerProvider =
    FutureProvider.autoDispose.family<void, String>((ref, id) {
  return ref.watch(listingsRepositoryProvider).incrementView(id);
});

final sellerListingsProvider =
    FutureProvider.family<List<Listing>, String>((ref, sellerId) {
  return ref.watch(listingsRepositoryProvider).fetchBySeller(sellerId);
});

final similarListingsProvider =
    FutureProvider.family<List<Listing>, ListingCategory>((ref, category) {
  return ref
      .watch(listingsRepositoryProvider)
      .fetchFeed(filter: ListingFilter(category: category));
});
