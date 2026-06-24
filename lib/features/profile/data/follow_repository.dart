import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Reads/writes the `follows` graph. Follower/following counts on profiles are
/// maintained automatically by the DB trigger (sync_follow_counts).
class FollowRepository {
  FollowRepository(this._client);
  final SupabaseClient _client;
  static const _table = 'follows';

  /// The set of user ids the current user follows.
  Future<Set<String>> fetchFollowingIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final data =
        await _client.from(_table).select('following_id').eq('follower_id', uid);
    return data.map<String>((e) => e['following_id'] as String).toSet();
  }

  Future<void> follow(String userId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from(_table)
        .upsert({'follower_id': uid, 'following_id': userId});
  }

  Future<void> unfollow(String userId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from(_table)
        .delete()
        .eq('follower_id', uid)
        .eq('following_id', userId);
  }
}

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(ref.watch(supabaseClientProvider));
});
