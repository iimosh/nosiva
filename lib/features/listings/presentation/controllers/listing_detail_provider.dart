import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/listings_repository.dart';
import '../../domain/listing.dart';
import '../../domain/listing_enums.dart';
import '../../domain/listing_filter.dart';

final listingDetailProvider =
    FutureProvider.family<Listing, String>((ref, id) {
  return ref.watch(listingsRepositoryProvider).fetchById(id);
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
