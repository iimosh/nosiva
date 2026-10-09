import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Thrown when the user still has orders in progress.
class OpenOrdersException implements Exception {}

class AccountRepository {
  AccountRepository(this._client);
  final SupabaseClient _client;

  /// Permanently deletes the signed-in user's account and their uploaded
  /// files. Refuses (before touching anything) while they have open orders.
  Future<void> deleteAccount() async {
    final uid = _client.auth.currentUser!.id;

    final open = await _client
        .from('orders')
        .select('id')
        .or('buyer_id.eq.$uid,seller_id.eq.$uid')
        .not('status', 'in', '(delivered,cancelled)')
        .limit(1);
    if (open.isNotEmpty) throw OpenOrdersException();

    await _removeUploadedFiles(uid);

    try {
      await _client.rpc('delete_my_account');
    } on PostgrestException catch (e) {
      if (e.message.contains('open_orders')) throw OpenOrdersException();
      rethrow;
    }

    // The account no longer exists server-side, so only clear the local session.
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
  }

  /// Best effort: a leftover file must never block the deletion itself.
  Future<void> _removeUploadedFiles(String uid) async {
    await _removeFolder('avatars', uid);
    await _removeFolder('listing-images', uid);
    try {
      final convos = await _client
          .from('conversations')
          .select('id')
          .or('buyer_id.eq.$uid,seller_id.eq.$uid');
      for (final c in convos) {
        await _removeFolder('chat-images', '${c['id']}/$uid');
      }
    } catch (_) {}
  }

  Future<void> _removeFolder(String bucket, String prefix) async {
    try {
      final storage = _client.storage.from(bucket);
      final items = await storage.list(
        path: prefix,
        searchOptions: const SearchOptions(limit: 1000),
      );
      final files = <String>[];
      for (final item in items) {
        final path = '$prefix/${item.name}';
        if (item.id == null) {
          await _removeFolder(bucket, path);
        } else {
          files.add(path);
        }
      }
      if (files.isNotEmpty) await storage.remove(files);
    } catch (_) {}
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(supabaseClientProvider));
});
