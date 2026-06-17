import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/listings_repository.dart';
import '../../domain/listing.dart';

final listingDetailProvider =
    FutureProvider.family<Listing, String>((ref, id) {
  return ref.watch(listingsRepositoryProvider).fetchById(id);
});
