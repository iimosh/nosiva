import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/live/live_updates.dart';
import '../../../core/neon/neon_functions.dart';
import '../domain/offer.dart';

class OffersRepository {
  OffersRepository(this._client, this._functions, this._live);
  final SupabaseClient _client;
  final NeonFunctions _functions;
  final LiveUpdates _live;
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
    // Copied onto the order if the seller accepts (cash on delivery).
    String? shippingAddress,
    String? buyerPhone,
  }) async {
    final uid = requireUserId();
    final data = await _client
        .from(_table)
        .insert({
          'listing_id': listingId,
          'buyer_id': uid,
          'seller_id': sellerId,
          'amount': amount,
          'message': message,
          'shipping_address': shippingAddress,
          'buyer_phone': buyerPhone,
        })
        .select(_select)
        .single();
    // Show it right away, and send the other person's notification now
    // rather than at the next minute.
    _live.ping();
    unawaited(_functions.nudgePush());
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
    return _live.watch(
      () => fetchAsBuyer(userId: userId, archived: archived),
      every: const Duration(seconds: 30),
    );
  }

  Stream<List<Offer>> watchAsSeller({
    required String userId,
    bool archived = false,
  }) {
    return _live.watch(
      () => fetchAsSeller(userId: userId, archived: archived),
      every: const Duration(seconds: 30),
    );
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
    final uid = requireUserId();
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
    // Show it right away, and send the other person's notification now
    // rather than at the next minute.
    _live.ping();
    unawaited(_functions.nudgePush());
  }

  Future<void> markRead(String offerId) async {
    final uid = requireUserId();
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
    final uid = requireUserId();
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
    final uid = requireUserId();
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
    final uid = requireUserId();
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
  return OffersRepository(
    ref.watch(dataClientProvider),
    ref.watch(neonFunctionsProvider),
    ref.watch(liveUpdatesProvider),
  );
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
