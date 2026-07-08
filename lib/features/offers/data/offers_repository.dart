import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/offer.dart';

class OffersRepository {
  OffersRepository(this._client);
  final SupabaseClient _client;
  static const _table = 'offers';
  static const _select =
      '*, listing:listings(*, images:listing_images(*)), '
      'buyer:profiles!offers_buyer_id_fkey(*), '
      'seller:profiles!offers_seller_id_fkey(*)';

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
        .select(_select)
        .single();
    return Offer.fromJson(data);
  }

  Future<List<Offer>> fetchAsBuyer({
    required String userId,
    bool archived = false,
  }) async {
    final query = _client
        .from(_table)
        .select(_select)
        .eq('buyer_id', userId)
        .neq('status', 'accepted');
    final data = archived
        ? await query.not('buyer_archived_at', 'is', null).order(
              'activity_at',
              ascending: false,
            )
        : await query.isFilter('buyer_archived_at', null).order(
              'activity_at',
              ascending: false,
            );
    return data.map<Offer>((e) => Offer.fromJson(e)).toList();
  }

  Future<List<Offer>> fetchAsSeller({
    required String userId,
    bool archived = false,
  }) async {
    final query = _client
        .from(_table)
        .select(_select)
        .eq('seller_id', userId)
        .neq('status', 'accepted');
    final data = archived
        ? await query.not('seller_archived_at', 'is', null).order(
              'activity_at',
              ascending: false,
            )
        : await query.isFilter('seller_archived_at', null).order(
              'activity_at',
              ascending: false,
            );
    return data.map<Offer>((e) => Offer.fromJson(e)).toList();
  }

  Stream<List<Offer>> watchAsBuyer({
    required String userId,
    bool archived = false,
  }) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('buyer_id', userId)
        .order('activity_at')
        .asyncMap((_) => fetchAsBuyer(userId: userId, archived: archived));
  }

  Stream<List<Offer>> watchAsSeller({
    required String userId,
    bool archived = false,
  }) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('seller_id', userId)
        .order('activity_at')
        .asyncMap((_) => fetchAsSeller(userId: userId, archived: archived));
  }

  Future<List<Offer>> fetchForListing(String listingId) async {
    final data = await _client
        .from(_table)
        .select(_select)
        .eq('listing_id', listingId)
        .order('created_at', ascending: false);
    return data.map<Offer>((e) => Offer.fromJson(e)).toList();
  }

  Future<void> respond(String offerId, String status) async {
    final uid = _client.auth.currentUser!.id;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from(_table)
        .update({
          'status': status,
          'activity_at': now,
          'seller_seen_at': now,
          'buyer_seen_at': null,
          'buyer_archived_at': null,
          'seller_archived_at': null,
        })
        .eq('id', offerId)
        .eq('seller_id', uid)
        .select('id')
        .single();
  }

  Future<void> markRead(String offerId) async {
    final uid = _client.auth.currentUser!.id;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from(_table)
        .update({'buyer_seen_at': now})
        .eq('id', offerId)
        .eq('buyer_id', uid);
    await _client
        .from(_table)
        .update({'seller_seen_at': now})
        .eq('id', offerId)
        .eq('seller_id', uid);
  }

  Future<void> markAllRead() async {
    final uid = _client.auth.currentUser!.id;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from(_table)
        .update({'buyer_seen_at': now})
        .eq('buyer_id', uid);
    await _client
        .from(_table)
        .update({'seller_seen_at': now})
        .eq('seller_id', uid);
  }

  Future<void> archive(String offerId) async {
    final uid = _client.auth.currentUser!.id;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from(_table)
        .update({'buyer_archived_at': now})
        .eq('id', offerId)
        .eq('buyer_id', uid);
    await _client
        .from(_table)
        .update({'seller_archived_at': now})
        .eq('id', offerId)
        .eq('seller_id', uid);
  }

  Future<void> unarchive(String offerId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from(_table)
        .update({'buyer_archived_at': null})
        .eq('id', offerId)
        .eq('buyer_id', uid);
    await _client
        .from(_table)
        .update({'seller_archived_at': null})
        .eq('id', offerId)
        .eq('seller_id', uid);
  }
}

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  return OffersRepository(ref.watch(supabaseClientProvider));
});

final buyerOffersProvider = StreamProvider<List<Offer>>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return Stream.value(const <Offer>[]);
  return ref.watch(offersRepositoryProvider).watchAsBuyer(userId: uid);
});

final sellerOffersProvider = StreamProvider<List<Offer>>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return Stream.value(const <Offer>[]);
  return ref.watch(offersRepositoryProvider).watchAsSeller(userId: uid);
});

final archivedBuyerOffersProvider = StreamProvider<List<Offer>>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return Stream.value(const <Offer>[]);
  return ref
      .watch(offersRepositoryProvider)
      .watchAsBuyer(userId: uid, archived: true);
});

final archivedSellerOffersProvider = StreamProvider<List<Offer>>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return Stream.value(const <Offer>[]);
  return ref
      .watch(offersRepositoryProvider)
      .watchAsSeller(userId: uid, archived: true);
});

final unreadOfferActivityCountProvider = Provider<int>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return 0;

  final buying = ref.watch(buyerOffersProvider).valueOrNull ?? const <Offer>[];
  final selling =
      ref.watch(sellerOffersProvider).valueOrNull ?? const <Offer>[];

  final unreadOfferIds = <String>{};
  for (final offer in [...buying, ...selling]) {
    if (offer.isUnreadFor(uid)) unreadOfferIds.add(offer.id);
  }
  return unreadOfferIds.length;
});
