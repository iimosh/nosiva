import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/neon/neon_functions.dart';
import '../domain/profile.dart';

class FollowRepository {
  FollowRepository(this._client, this._functions);
  final SupabaseClient _client;
  final NeonFunctions _functions;
  static const _table = 'follows';

  Future<Set<String>> fetchFollowingIds() async {
    final uid = currentUserId();
    if (uid == null) return {};
    final data =
        await _client.from(_table).select('following_id').eq('follower_id', uid);
    return data.map<String>((e) => e['following_id'] as String).toSet();
  }

  Future<void> follow(String userId) async {
    final uid = requireUserId();
    await _client
        .from(_table)
        .upsert({'follower_id': uid, 'following_id': userId});
    // Send their notification now rather than at the next safety check.
    unawaited(_functions.nudgePush());
  }

  Future<void> unfollow(String userId) async {
    final uid = requireUserId();
    await _client
        .from(_table)
        .delete()
        .eq('follower_id', uid)
        .eq('following_id', userId);
  }

  Future<List<Profile>> fetchFollowers(String userId) async {
    final data = await _client
        .from(_table)
        .select('follower:profiles!follows_follower_id_fkey(*)')
        .eq('following_id', userId);
    return data
        .map<Profile>(
            (e) => Profile.fromJson(e['follower'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Profile>> fetchFollowing(String userId) async {
    final data = await _client
        .from(_table)
        .select('following:profiles!follows_following_id_fkey(*)')
        .eq('follower_id', userId);
    return data
        .map<Profile>(
            (e) => Profile.fromJson(e['following'] as Map<String, dynamic>))
        .toList();
  }
}

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(
    ref.watch(dataClientProvider),
    ref.watch(neonFunctionsProvider),
  );
});
