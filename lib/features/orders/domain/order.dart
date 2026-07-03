import 'package:freezed_annotation/freezed_annotation.dart';

import '../../listings/domain/listing.dart';
import '../../listings/domain/listing_enums.dart';
import '../../profile/domain/profile.dart';

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
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'activity_at') DateTime? activityAt,
    @JsonKey(name: 'buyer_seen_at') DateTime? buyerSeenAt,
    @JsonKey(name: 'seller_seen_at') DateTime? sellerSeenAt,
    // Joined
    Listing? listing,
    Profile? buyer,
    Profile? seller,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  OrderStatus get statusEnum => OrderStatus.fromValue(status);

  Profile? counterparty(String userId) => userId == sellerId ? buyer : seller;

  DateTime? get activityTime => activityAt ?? updatedAt ?? createdAt;

  bool get canArchiveFromActivity =>
      statusEnum == OrderStatus.delivered || statusEnum == OrderStatus.cancelled;

  bool isUnreadFor(String userId) {
    if (userId == buyerId) return buyerSeenAt == null;
    if (userId == sellerId) return sellerSeenAt == null;
    return false;
  }
}
