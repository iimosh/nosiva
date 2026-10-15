import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Tells the server which phones belong to the signed-in account, so
/// notifications reach them (see migration 0026).
class PushTokensRepository {
  PushTokensRepository(this._client);
  final SupabaseClient _client;

  /// Links this phone's Firebase token to the signed-in account, with the
  /// app language notifications should be written in. Also moves the token
  /// over if someone else was signed in on this phone before.
  Future<void> register(String token, {required String languageCode}) =>
      _client.rpc('register_push_token', params: {
        'p_token': token,
        'p_locale': languageCode == 'mk' ? 'mk' : 'en',
        'p_platform': 'android',
      });

  Future<void> unregister(String token) =>
      _client.rpc('unregister_push_token', params: {'p_token': token});
}

final pushTokensRepositoryProvider = Provider<PushTokensRepository>((ref) {
  return PushTokensRepository(ref.watch(supabaseClientProvider));
});
