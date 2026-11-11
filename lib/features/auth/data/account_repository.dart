import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/neon/neon_auth.dart';
import '../../../core/neon/neon_functions.dart';

/// Thrown when the user still has orders in progress.
class OpenOrdersException implements Exception {}

class AccountRepository {
  AccountRepository(this._client, this._functions, this._auth);
  final SupabaseClient _client;
  final NeonFunctions _functions;
  final NeonAuth _auth;

  /// Permanently deletes the signed-in user's account and their uploaded
  /// photos. Refuses (before touching anything) while they have open orders.
  Future<void> deleteAccount() async {
    final uid = requireUserId();

    final open = await _client
        .from('orders')
        .select('id')
        .or('buyer_id.eq.$uid,seller_id.eq.$uid')
        .not('status', 'in', '(delivered,cancelled)')
        .limit(1);
    if (open.isNotEmpty) throw OpenOrdersException();

    // Photos first, while the session still exists. Best effort: a leftover
    // file must never block the deletion itself.
    try {
      await _functions.deleteMyPhotos();
    } catch (_) {}

    try {
      await _client.rpc('delete_my_account', params: const {});
    } on PostgrestException catch (e) {
      if (e.message.contains('open_orders')) throw OpenOrdersException();
      rethrow;
    }

    // The account no longer exists server-side; clear this phone's session.
    await _auth.forgetLocalSession();
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    ref.watch(dataClientProvider),
    ref.watch(neonFunctionsProvider),
    ref.watch(neonAuthProvider),
  );
});
