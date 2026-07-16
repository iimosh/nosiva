import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';

class MessagingRepository {
  MessagingRepository(this._client);
  final SupabaseClient _client;

  static const _conversations = 'conversations';
  static const _messages = 'messages';
  static const _chatImagesBucket = 'chat-images';

  static const _conversationSelect =
      '*, buyer:profiles!conversations_buyer_id_fkey(*), '
      'seller:profiles!conversations_seller_id_fkey(*), '
      'listing:listings(id, title, listing_images(id, listing_id, image_url, position))';

  /// Finds an existing buyer-seller conversation for a listing, or creates one.
  Future<Conversation> getOrCreateConversation({
    required String listingId,
    required String sellerId,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final existing = await _client
        .from(_conversations)
        .select()
        .eq('listing_id', listingId)
        .eq('buyer_id', uid)
        .eq('seller_id', sellerId)
        .maybeSingle();
    if (existing != null) return Conversation.fromJson(existing);

    final created = await _client
        .from(_conversations)
        .insert({
          'listing_id': listingId,
          'buyer_id': uid,
          'seller_id': sellerId,
        })
        .select()
        .single();
    return Conversation.fromJson(created);
  }

  Future<Conversation> getOrCreateDirectConversation(String otherUserId) async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from(_conversations)
        .select()
        .isFilter('listing_id', null)
        .or('and(buyer_id.eq.$uid,seller_id.eq.$otherUserId),'
            'and(buyer_id.eq.$otherUserId,seller_id.eq.$uid)')
        .limit(1);
    if (rows.isNotEmpty) return Conversation.fromJson(rows.first);

    final created = await _client
        .from(_conversations)
        .insert({'buyer_id': uid, 'seller_id': otherUserId})
        .select()
        .single();
    return Conversation.fromJson(created);
  }

  Future<void> markConversationRead(String conversationId) async {
    await _client
        .rpc('mark_conversation_read', params: {'conv': conversationId});
  }

  /// Hides a conversation from the caller's inbox. It reappears automatically
  /// if the other participant sends a new message.
  Future<void> hideConversation(String conversationId) async {
    await _client.rpc('hide_conversation', params: {'conv': conversationId});
  }

  Future<Conversation> fetchConversation(String id) async {
    final data = await _client
        .from(_conversations)
        .select(_conversationSelect)
        .eq('id', id)
        .single();
    return Conversation.fromJson(data);
  }

  Future<List<Conversation>> fetchConversations() async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from(_conversations)
        .select(_conversationSelect)
        .or('and(buyer_id.eq.$uid,deleted_by_buyer.eq.false),'
            'and(seller_id.eq.$uid,deleted_by_seller.eq.false)')
        .order('last_message_at', ascending: false);
    return data.map<Conversation>((e) => Conversation.fromJson(e)).toList();
  }

  Stream<List<Message>> messageStream(String conversationId) {
    return _client
        .from(_messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(Message.fromJson).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String body,
    String? imageUrl,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from(_messages).insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'body': body,
      'image_url': imageUrl,
    });
  }

  Future<String> uploadChatImage({
    required String conversationId,
    required Uint8List bytes,
    required String ext,
  }) async {
    final uid = _client.auth.currentUser!.id;
    const uuid = Uuid();
    final normalizedExt = ext == 'jpeg' ? 'jpg' : ext;
    final path = '$conversationId/$uid/${uuid.v4()}.$normalizedExt';

    await _client.storage.from(_chatImagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType:
                'image/${normalizedExt == 'jpg' ? 'jpeg' : normalizedExt}',
            upsert: true,
          ),
        );

    return _client.storage.from(_chatImagesBucket).getPublicUrl(path);
  }
}

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(ref.watch(supabaseClientProvider));
});
