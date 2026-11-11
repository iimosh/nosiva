import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/live/live_updates.dart';
import '../../../core/neon/neon_functions.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';

class MessagingRepository {
  MessagingRepository(this._client, this._functions, this._live);
  final SupabaseClient _client;
  final NeonFunctions _functions;
  final LiveUpdates _live;

  static const _conversations = 'conversations';
  static const _messages = 'messages';

  static const _conversationSelect =
      '*, buyer:profiles!conversations_buyer_id_fkey(*), '
      'seller:profiles!conversations_seller_id_fkey(*), '
      'listing:listings(id, title, listing_images(id, listing_id, image_url, position))';

  /// Finds an existing buyer-seller conversation for a listing, or creates one.
  Future<Conversation> getOrCreateConversation({
    required String listingId,
    required String sellerId,
  }) async {
    final uid = requireUserId();
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

  static final _uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  Future<Conversation> getOrCreateDirectConversation(String otherUserId) async {
    // otherUserId is interpolated into a PostgREST filter string below and can
    // originate from a route parameter, so only a real UUID may pass.
    if (!_uuidPattern.hasMatch(otherUserId)) {
      throw ArgumentError.value(otherUserId, 'otherUserId', 'Not a valid user id');
    }
    final uid = requireUserId();
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
    final uid = requireUserId();
    final data = await _client
        .from(_conversations)
        .select(_conversationSelect)
        .or('and(buyer_id.eq.$uid,deleted_by_buyer.eq.false),'
            'and(seller_id.eq.$uid,deleted_by_seller.eq.false)')
        // Opening a chat creates the conversation; it only shows in the
        // inbox (for either person) once someone has written something.
        .not('last_message_at', 'is', null)
        .order('last_message_at', ascending: false);
    return data.map<Conversation>((e) => Conversation.fromJson(e)).toList();
  }

  /// The chat's messages, kept fresh while it's open: checked every few
  /// seconds, and straight away when a notification arrives.
  Stream<List<Message>> messageStream(String conversationId) {
    return _live.watch(
      () => fetchMessages(conversationId),
      every: const Duration(seconds: 3),
    );
  }

  Future<List<Message>> fetchMessages(String conversationId) async {
    final rows = await _client
        .from(_messages)
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return rows.map(Message.fromJson).toList();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String body,
    String? imageUrl,
  }) async {
    final uid = requireUserId();
    await _client.from(_messages).insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'body': body,
      'image_url': imageUrl,
    });
    // Show it right away, and send the other person's notification now
    // rather than at the next minute.
    _live.ping();
    unawaited(_functions.nudgePush());
  }

  /// Uploads a chat photo to the conversation's private folder and returns
  /// its storage path (what the message stores). It's shown through a
  /// short-lived link — see chat_images.dart.
  Future<String> uploadChatImage({
    required String conversationId,
    required Uint8List bytes,
    required String ext,
  }) async {
    // The media function checks the person is in this conversation and
    // picks the folder ("<conversation>/<sender>/…") from the sign-in token.
    final photo = await _functions.uploadPhoto(
      kind: MediaKind.chat,
      bytes: bytes,
      contentType: imageContentType(ext),
      conversationId: conversationId,
    );
    return photo.path;
  }
}

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(
    ref.watch(dataClientProvider),
    ref.watch(neonFunctionsProvider),
    ref.watch(liveUpdatesProvider),
  );
});
