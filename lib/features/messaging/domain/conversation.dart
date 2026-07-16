import 'package:freezed_annotation/freezed_annotation.dart';

import '../../listings/domain/listing_image.dart';
import '../../profile/domain/profile.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// Lightweight listing context for a conversation row — just enough to show
/// a thumbnail + title in the inbox without pulling the full [Listing].
@freezed
class ConversationListing with _$ConversationListing {
  const ConversationListing._();

  const factory ConversationListing({
    required String id,
    required String title,
    @Default(<ListingImage>[]) @JsonKey(name: 'listing_images')
    List<ListingImage> images,
  }) = _ConversationListing;

  factory ConversationListing.fromJson(Map<String, dynamic> json) =>
      _$ConversationListingFromJson(json);

  String? get coverImageUrl {
    if (images.isEmpty) return null;
    final sorted = [...images]..sort((a, b) => a.position.compareTo(b.position));
    return sorted.first.imageUrl;
  }
}

@freezed
class Conversation with _$Conversation {
  const Conversation._();

  const factory Conversation({
    required String id,
    @JsonKey(name: 'listing_id') String? listingId,
    @JsonKey(name: 'buyer_id') required String buyerId,
    @JsonKey(name: 'seller_id') required String sellerId,
    @JsonKey(name: 'last_message') String? lastMessage,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @Default(0) @JsonKey(name: 'buyer_unread') int buyerUnread,
    @Default(0) @JsonKey(name: 'seller_unread') int sellerUnread,
    @JsonKey(name: 'buyer') Profile? buyer,
    @JsonKey(name: 'seller') Profile? seller,
    @JsonKey(name: 'listing') ConversationListing? listing,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

 int unreadFor(String userId) =>
      userId == buyerId ? buyerUnread : userId == sellerId ? sellerUnread : 0;

 Profile? otherParticipant(String userId) =>
      userId == buyerId ? seller : buyer;
}
