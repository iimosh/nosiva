import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/live/live_updates.dart';
import '../../../core/neon/neon_functions.dart';
import '../domain/order.dart';

class OrdersRepository {
  OrdersRepository(this._client, this._functions, this._live);
  final SupabaseClient _client;
  final NeonFunctions _functions;
  final LiveUpdates _live;
  static const _table = 'orders';
  static const _select =
      '*, listing:listings(*, images:listing_images(*)), '
      'buyer:profiles!orders_buyer_id_fkey(*), '
      'seller:profiles!orders_seller_id_fkey(*)';

  /// Creates an order request for the seller to accept. There's no payment in
  /// the app: the buyer pays the courier in cash on delivery.
  Future<Order> createOrder({
    required String listingId,
    required String sellerId,
    required num total,
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
          'total': total,
          'shipping_address': shippingAddress,
          'buyer_phone': buyerPhone,
          'status': 'pending',
        })
        .select(_select)
        .single();
    // Show it right away, and send the other person's notification now
    // rather than at the next minute.
    _live.ping();
    unawaited(_functions.nudgePush());
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
    return _live.watch(
      () => fetchAsBuyer(userId: userId, archived: archived),
      every: const Duration(seconds: 30),
    );
  }

  Stream<List<Order>> watchAsSeller({
    required String userId,
    bool archived = false,
  }) {
    return _live.watch(
      () => fetchAsSeller(userId: userId, archived: archived),
      every: const Duration(seconds: 30),
    );
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
    // Show it right away, and send the other person's notification now
    // rather than at the next minute.
    _live.ping();
    unawaited(_functions.nudgePush());
  }

  Future<void> markRead(String orderId) async {
    final uid = requireUserId();
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

  Future<void> archive(String orderId) async {
    final uid = requireUserId();
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
    final uid = requireUserId();
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
  return OrdersRepository(
    ref.watch(dataClientProvider),
    ref.watch(neonFunctionsProvider),
    ref.watch(liveUpdatesProvider),
  );
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
