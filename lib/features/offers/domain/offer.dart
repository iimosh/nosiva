import 'package:freezed_annotation/freezed_annotation.dart';

import '../../listings/domain/listing_enums.dart';

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
  }) = _Offer;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);

  OfferStatus get statusEnum => OfferStatus.fromValue(status);
}
