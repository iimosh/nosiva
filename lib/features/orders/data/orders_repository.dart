import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/order.dart';

class OrdersRepository {
  OrdersRepository(this._client);
  final SupabaseClient _client;
  static const _table = 'orders';
  static const _select =
      '*, listing:listings(*, images:listing_images(*))';

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

  Future<List<Order>> fetchAsBuyer() async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from(_table)
        .select(_select)
        .eq('buyer_id', uid)
        .order('created_at', ascending: false);
    return data.map<Order>((e) => Order.fromJson(e)).toList();
  }

  Future<List<Order>> fetchAsSeller() async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from(_table)
        .select(_select)
        .eq('seller_id', uid)
        .order('created_at', ascending: false);
    return data.map<Order>((e) => Order.fromJson(e)).toList();
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _client.from(_table).update({'status': status}).eq('id', orderId);
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(supabaseClientProvider));
});
