import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'profiles';
  static const _avatarsBucket = 'avatars';

  Future<Profile?> fetchById(String id) async {
    final data = await _withTransientRetry(
      () => _client.from(_table).select().eq('id', id).maybeSingle(),
    );
    return data == null ? null : Profile.fromJson(data);
  }

  Future<void> setRole(String userId, String role) async {
    await _client.from(_table).update({'role': role}).eq('id', userId);
  }

  Future<List<Profile>> search(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final data = await _client
        .from(_table)
        .select()
        .or('username.ilike.%$q%,display_name.ilike.%$q%')
        .limit(limit);
    return data.map<Profile>((e) => Profile.fromJson(e)).toList();
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
    final data = await _withTransientRetry(
      () => _client
          .from(_table)
          .upsert({'id': id, 'username': username}, onConflict: 'id')
          .select()
          .single(),
    );
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

  Future<Profile> updateProfile({
    required String id,
    required String username,
    String? displayName,
    String? bio,
    String? location,
    required List<String> vibeTags,
  }) async {
    final data = await _client
        .from(_table)
        .update({
          'username': username,
          'display_name': displayName,
          'bio': bio,
          'location': location,
          'vibe_tags': vibeTags,
        })
        .eq('id', id)
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
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String ext,
  }) async {
    final normalizedExt = ext == 'jpeg' ? 'jpg' : ext;
    final path = '$userId/${const Uuid().v4()}.$normalizedExt';
    await _client.storage.from(_avatarsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType:
                'image/${normalizedExt == 'jpg' ? 'jpeg' : normalizedExt}',
            upsert: true,
          ),
        );
    return _client.storage.from(_avatarsBucket).getPublicUrl(path);
  }

  Future<Profile> updateAvatar({
    required String id,
    required String? avatarUrl,
  }) async {
    final data = await _client
        .from(_table)
        .update({'avatar_url': avatarUrl})
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

  Future<T> _withTransientRetry<T>(Future<T> Function() request) async {
    Object? lastError;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await request();
      } catch (error) {
        lastError = error;
        if (!_isTransientNetworkError(error) || attempt == 2) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
      }
    }

    Error.throwWithStackTrace(lastError!, StackTrace.current);
  }

  bool _isTransientNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('clientexception') ||
        message.contains('ssl') ||
        message.contains('socketexception') ||
        message.contains('connection') ||
        message.contains('failed host lookup');
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});
