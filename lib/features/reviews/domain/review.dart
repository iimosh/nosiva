import 'package:freezed_annotation/freezed_annotation.dart';

import '../../profile/domain/profile.dart';

part 'review.freezed.dart';
part 'review.g.dart';

@freezed
class Review with _$Review {
  const Review._();

  const factory Review({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'reviewer_id') required String reviewerId,
    @JsonKey(name: 'reviewee_id') required String revieweeId,
    required int rating,
    String? comment,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    Profile? reviewer,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) =>
      _$ReviewFromJson(json);
}
