import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../listings/domain/listing.dart';

/// Local, in-memory cart. Since listings are unique items, the cart is a set
/// of listings keyed by id.
class CartController extends Notifier<List<Listing>> {
  @override
  List<Listing> build() => [];

  bool contains(String listingId) => state.any((l) => l.id == listingId);

  void add(Listing listing) {
    if (contains(listing.id)) return;
    state = [...state, listing];
  }

  void remove(String listingId) {
    state = state.where((l) => l.id != listingId).toList();
  }

  void clear() => state = [];

  num get total => state.fold<num>(0, (sum, l) => sum + l.price);
}

final cartControllerProvider =
    NotifierProvider<CartController, List<Listing>>(CartController.new);
