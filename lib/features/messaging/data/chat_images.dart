import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Chat photos live in the private 'chat-images' bucket and are shown
/// through short-lived signed links, readable only by the two people in the
/// conversation (see migration 0025).
const chatImagesBucket = 'chat-images';

/// Longest side, in pixels, a chat photo is scaled down to before upload.
const kChatPhotoMaxDimension = 1600.0;

const _publicPrefix = '/storage/v1/object/public/$chatImagesBucket/';
final _pathPattern =
    RegExp(r'^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}/[A-Za-z0-9._-]+$');

/// The storage path of a chat photo, from what a message stores: the path
/// itself (new messages) or an old public link (messages sent before photos
/// became private). Null for anything else — the app never loads a photo
/// from outside its own private bucket.
String? chatImagePath(String stored) {
  var path = stored;
  final i = stored.indexOf(_publicPrefix);
  if (i >= 0) path = Uri.decodeComponent(stored.substring(i + _publicPrefix.length));
  if (path.contains('..') || !_pathPattern.hasMatch(path)) return null;
  return path;
}

/// A link to show a chat photo, valid for an hour. Kept for 50 minutes so
/// scrolling a chat doesn't ask for new links; the photo itself is cached
/// on the phone by its path, not by the link.
final chatImageUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, path) async {
  final url = await ref
      .watch(supabaseClientProvider)
      .storage
      .from(chatImagesBucket)
      .createSignedUrl(path, 3600);
  final keep = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 50), keep.close);
  ref.onDispose(timer.cancel);
  return url;
});
