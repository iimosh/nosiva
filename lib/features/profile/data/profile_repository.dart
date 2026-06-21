import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'profiles';

  Future<Profile?> fetchById(String id) async {
    final data =
        await _client.from(_table).select().eq('id', id).maybeSingle();
    return data == null ? null : Profile.fromJson(data);
  }


  Future<List<Profile>> fetchAll({int limit = 100}) async {
    final data = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map<Profile>((e) => Profile.fromJson(e)).toList();
  }

  Future<Profile> createInitial({
    required String id,
    required String username,
  }) async {
    final data = await _client
        .from(_table)
        .insert({'id': id, 'username': username})
        .select()
        .single();
    return Profile.fromJson(data);
  }

  Future<Profile> upsert(Profile profile) async {
    final data = await _client
        .from(_table)
        .upsert(profile.toJson())
        .select()
        .single();
    return Profile.fromJson(data);
  }

  Future<Profile> completeOnboarding({
    required String id,
    String? displayName,
    String? location,
    required List<String> vibeTags,
  }) async {
    final data = await _client
        .from(_table)
        .update({
          if (displayName != null) 'display_name': displayName,
          if (location != null) 'location': location,
          'vibe_tags': vibeTags,
          'onboarded': true,
        })
        .eq('id', id)
        .select()
        .single();
    return Profile.fromJson(data);
  }

  Future<bool> usernameAvailable(String username) async {
    final existing = await _client
        .from(_table)
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return existing == null;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});
