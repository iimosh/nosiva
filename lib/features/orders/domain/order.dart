import 'package:freezed_annotation/freezed_annotation.dart';

import '../../listings/domain/listing.dart';
import '../../listings/domain/listing_enums.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
class Order with _$Order {
  const Order._();

  const factory Order({
    required String id,
    @JsonKey(name: 'listing_id') required String listingId,
    @JsonKey(name: 'buyer_id') required String buyerId,
    @JsonKey(name: 'seller_id') required String sellerId,
    required num total,
    @Default('pending') String status,
    @JsonKey(name: 'shipping_address') String? shippingAddress,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    // Joined
    Listing? listing,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  OrderStatus get statusEnum => OrderStatus.fromValue(status);
}
