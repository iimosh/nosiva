import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/offer.dart';

class OffersRepository {
  OffersRepository(this._client);
  final SupabaseClient _client;
  static const _table = 'offers';

  Future<Offer> createOffer({
    required String listingId,
    required String sellerId,
    required num amount,
    String? message,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from(_table)
        .insert({
          'listing_id': listingId,
          'buyer_id': uid,
          'seller_id': sellerId,
          'amount': amount,
          'message': message,
        })
        .select()
        .single();
    return Offer.fromJson(data);
  }

  Future<List<Offer>> fetchForListing(String listingId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('listing_id', listingId)
        .order('created_at', ascending: false);
    return data.map<Offer>((e) => Offer.fromJson(e)).toList();
  }

  Future<void> respond(String offerId, String status) async {
    await _client.from(_table).update({'status': status}).eq('id', offerId);
  }
}

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  return OffersRepository(ref.watch(supabaseClientProvider));
});
