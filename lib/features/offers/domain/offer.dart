import 'package:freezed_annotation/freezed_annotation.dart';

import '../../listings/domain/listing.dart';
import '../../listings/domain/listing_enums.dart';
import '../../profile/domain/profile.dart';

part 'offer.freezed.dart';
part 'offer.g.dart';

@freezed
class Offer with _$Offer {
  const Offer._();

  const factory Offer({
    required String id,
    @JsonKey(name: 'listing_id') required String listingId,
    @JsonKey(name: 'buyer_id') required String buyerId,
    @JsonKey(name: 'seller_id') required String sellerId,
    required num amount,
    @Default('pending') String status,
    String? message,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'activity_at') DateTime? activityAt,
    @JsonKey(name: 'buyer_seen_at') DateTime? buyerSeenAt,
    @JsonKey(name: 'seller_seen_at') DateTime? sellerSeenAt,
    @JsonKey(name: 'buyer_archived_at') DateTime? buyerArchivedAt,
    @JsonKey(name: 'seller_archived_at') DateTime? sellerArchivedAt,
    @JsonKey(name: 'order_id') String? orderId,
    Listing? listing,
    Profile? buyer,
    Profile? seller,
  }) = _Offer;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);

  OfferStatus get statusEnum => OfferStatus.fromValue(status);

  DateTime? get activityTime => activityAt ?? updatedAt ?? createdAt;

  bool get canArchiveFromActivity => statusEnum != OfferStatus.pending;

  Profile? counterparty(String userId) => userId == sellerId ? buyer : seller;

  bool isUnreadFor(String userId) {
    if (userId == buyerId) return buyerSeenAt == null;
    if (userId == sellerId) return sellerSeenAt == null;
    return false;
  }
}
