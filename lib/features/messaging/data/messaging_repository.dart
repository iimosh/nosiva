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

  Future<Conversation> fetchConversation(String id) async {
    final data = await _client
        .from(_conversations)
        .select('*, buyer:profiles!conversations_buyer_id_fkey(*), '
            'seller:profiles!conversations_seller_id_fkey(*)')
        .eq('id', id)
        .single();
    return Conversation.fromJson(data);
  }

  Future<List<Conversation>> fetchConversations() async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from(_conversations)
        .select('*, buyer:profiles!conversations_buyer_id_fkey(*), '
            'seller:profiles!conversations_seller_id_fkey(*)')
        .or('buyer_id.eq.$uid,seller_id.eq.$uid')
        .order('last_message_at', ascending: false);
    return data.map<Conversation>((e) => Conversation.fromJson(e)).toList();
  }

  /// Realtime stream of messages in a conversation, ordered oldest-to-newest.
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
    await _client.from(_conversations).update({
      'last_message': imageUrl != null ? 'Photo' : body,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
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
