import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../listings/domain/listing.dart';

class FavoritesRepository {
  FavoritesRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'favorites';

  /// The set of listing ids the current user has favorited.
  Future<Set<String>> fetchFavoriteIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final data =
        await _client.from(_table).select('listing_id').eq('user_id', uid);
    return data.map<String>((e) => e['listing_id'] as String).toSet();
  }

  Future<List<Listing>> fetchFavoriteListings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client
        .from(_table)
        .select('listing:listings(*, images:listing_images(*), '
            'seller:profiles!listings_seller_id_fkey(*))')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return data
        .map<Listing>((e) => Listing.fromJson(e['listing'] as Map<String, dynamic>)
            .copyWith(isFavorited: true))
        .toList();
  }

  Future<void> add(String listingId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from(_table)
        .upsert({'user_id': uid, 'listing_id': listingId});
  }

  Future<void> remove(String listingId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from(_table)
        .delete()
        .eq('user_id', uid)
        .eq('listing_id', listingId);
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(supabaseClientProvider));
});
