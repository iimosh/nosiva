import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/order.dart';

class OrdersRepository {
  OrdersRepository(this._client);
  final SupabaseClient _client;
  static const _table = 'orders';
  static const _select =
      '*, listing:listings(*, images:listing_images(*)), '
      'buyer:profiles!orders_buyer_id_fkey(*), '
      'seller:profiles!orders_seller_id_fkey(*)';

  /// Creates an order. Payment is stubbed — see Stripe integration point in
  /// the checkout flow. This simply records a pending order row.
  Future<Order> createOrder({
    required String listingId,
    required String sellerId,
    required num total,
    String? shippingAddress,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from(_table)
        .insert({
          'listing_id': listingId,
          'buyer_id': uid,
          'seller_id': sellerId,
          'total': total,
          'shipping_address': shippingAddress,
          'status': 'pending',
        })
        .select(_select)
        .single();
    return Order.fromJson(data);
  }

  Future<List<Order>> fetchAsBuyer({
    required String userId,
    bool archived = false,
  }) async {
    final query = _client.from(_table).select(_select).eq('buyer_id', userId);
    final data = archived
        ? await query.not('buyer_archived_at', 'is', null).order(
              'activity_at',
              ascending: false,
            )
        : await query.isFilter('buyer_archived_at', null).order(
              'activity_at',
              ascending: false,
            );
    return _uniqueByListing(data.map<Order>((e) => Order.fromJson(e)));
  }

  Future<List<Order>> fetchAsSeller({
    required String userId,
    bool archived = false,
  }) async {
    final query = _client.from(_table).select(_select).eq('seller_id', userId);
    final data = archived
        ? await query.not('seller_archived_at', 'is', null).order(
              'activity_at',
              ascending: false,
            )
        : await query.isFilter('seller_archived_at', null).order(
              'activity_at',
              ascending: false,
            );
    return _uniqueByListing(data.map<Order>((e) => Order.fromJson(e)));
  }

  Stream<List<Order>> watchAsBuyer({
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

  Stream<List<Order>> watchAsSeller({
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

  Future<Order> fetchById(String id) async {
    final data = await _client.from(_table).select(_select).eq('id', id).single();
    return Order.fromJson(data);
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _client
        .from(_table)
        .update({'status': status})
        .eq('id', orderId)
        .select('id')
        .single();
  }

  Future<void> markRead(String orderId) async {
    final uid = _client.auth.currentUser!.id;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from(_table)
        .update({'buyer_seen_at': now})
        .eq('id', orderId)
        .eq('buyer_id', uid);
    await _client
        .from(_table)
        .update({'seller_seen_at': now})
        .eq('id', orderId)
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

  Future<void> archive(String orderId) async {
    final uid = _client.auth.currentUser!.id;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from(_table)
        .update({'buyer_archived_at': now})
        .eq('id', orderId)
        .eq('buyer_id', uid);
    await _client
        .from(_table)
        .update({'seller_archived_at': now})
        .eq('id', orderId)
        .eq('seller_id', uid);
  }

  Future<void> unarchive(String orderId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from(_table)
        .update({'buyer_archived_at': null})
        .eq('id', orderId)
        .eq('buyer_id', uid);
    await _client
        .from(_table)
        .update({'seller_archived_at': null})
        .eq('id', orderId)
        .eq('seller_id', uid);
  }

  List<Order> _uniqueByListing(Iterable<Order> orders) {
    final byListing = <String, Order>{};
    for (final order in orders) {
      byListing.putIfAbsent(order.listingId, () => order);
    }
    return byListing.values.toList();
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(supabaseClientProvider));
});

final buyerOrdersProvider = StreamProvider<List<Order>>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return Stream.value(const <Order>[]);
  return ref.watch(ordersRepositoryProvider).watchAsBuyer(userId: uid);
});

final sellerOrdersProvider = StreamProvider<List<Order>>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return Stream.value(const <Order>[]);
  return ref.watch(ordersRepositoryProvider).watchAsSeller(userId: uid);
});

final archivedBuyerOrdersProvider = StreamProvider<List<Order>>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return Stream.value(const <Order>[]);
  return ref
      .watch(ordersRepositoryProvider)
      .watchAsBuyer(userId: uid, archived: true);
});

final archivedSellerOrdersProvider = StreamProvider<List<Order>>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return Stream.value(const <Order>[]);
  return ref
      .watch(ordersRepositoryProvider)
      .watchAsSeller(userId: uid, archived: true);
});

final unreadOrderActivityCountProvider = Provider<int>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return 0;

  final buying = ref.watch(buyerOrdersProvider).valueOrNull ?? const <Order>[];
  final selling =
      ref.watch(sellerOrdersProvider).valueOrNull ?? const <Order>[];

  final unreadOrderIds = <String>{};
  for (final order in [...buying, ...selling]) {
    if (order.isUnreadFor(uid)) unreadOrderIds.add(order.id);
  }
  return unreadOrderIds.length;
});
