import 'package:freezed_annotation/freezed_annotation.dart';

import '../../profile/domain/profile.dart';
import 'listing_enums.dart';
import 'listing_image.dart';

part 'listing.freezed.dart';
part 'listing.g.dart';

/// A marketplace listing. Enum-like columns are stored as their raw string
/// [value] and surfaced through typed getters to keep (de)serialization trivial.
@freezed
class Listing with _$Listing {
  const Listing._();

  const factory Listing({
    required String id,
    @JsonKey(name: 'seller_id') required String sellerId,
    required String title,
    @Default('') String description,
    required String category,
    String? brand,
    String? size,
    required String condition,
    String? color,
    required num price,
    @Default('active') String status,
    @Default(<String>[]) @JsonKey(name: 'style_tags') List<String> styleTags,
    String? location,
    @Default(0) @JsonKey(name: 'favorite_count') int favoriteCount,
    @Default(0) @JsonKey(name: 'view_count') int viewCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    // Joined / computed (not always present)
    @Default(<ListingImage>[]) List<ListingImage> images,
    Profile? seller,
    @Default(false) @JsonKey(name: 'is_favorited') bool isFavorited,
  }) = _Listing;

  factory Listing.fromJson(Map<String, dynamic> json) => _$ListingFromJson(json);

  ListingCategory get categoryEnum => ListingCategory.fromValue(category);
  ItemCondition get conditionEnum => ItemCondition.fromValue(condition);
  ListingStatus get statusEnum => ListingStatus.fromValue(status);

  String? get coverImageUrl =>
      images.isNotEmpty ? images.first.imageUrl : null;
  bool get isSold => statusEnum == ListingStatus.sold;
}
