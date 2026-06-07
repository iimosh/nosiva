import 'package:freezed_annotation/freezed_annotation.dart';

import '../../profile/domain/profile.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    @JsonKey(name: 'listing_id') String? listingId,
    @JsonKey(name: 'buyer_id') required String buyerId,
    @JsonKey(name: 'seller_id') required String sellerId,
    @JsonKey(name: 'last_message') String? lastMessage,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    // Joined
    @JsonKey(name: 'buyer') Profile? buyer,
    @JsonKey(name: 'seller') Profile? seller,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
