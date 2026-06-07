import 'package:freezed_annotation/freezed_annotation.dart';

part 'listing_image.freezed.dart';
part 'listing_image.g.dart';

@freezed
class ListingImage with _$ListingImage {
  const factory ListingImage({
    required String id,
    @JsonKey(name: 'listing_id') required String listingId,
    @JsonKey(name: 'image_url') required String imageUrl,
    @Default(0) int position,
  }) = _ListingImage;

  factory ListingImage.fromJson(Map<String, dynamic> json) =>
      _$ListingImageFromJson(json);
}
