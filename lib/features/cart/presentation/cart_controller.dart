import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../listings/domain/listing.dart';

/// Local, in-memory cart. Since listings are unique items, the cart is a set
/// of listings keyed by id.
class CartController extends Notifier<List<Listing>> {
  @override
  List<Listing> build() {
    // Resets on every sign-in/sign-out, not just app restart — otherwise a
    // second account signing in on the same device would inherit whatever
    // was left in the previous person's cart.
    ref.watch(currentAuthUserProvider);
    return [];
  }

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
