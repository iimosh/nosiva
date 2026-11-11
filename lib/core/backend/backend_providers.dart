import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';

import '../config/env.dart';
import '../neon/neon_auth.dart';
import '../neon/neon_functions.dart';

/// Nosiva's backend is Neon:
///   * Neon Auth — accounts and sign-in ([neonAuthProvider]);
///   * the Neon Data API — tables and database functions. It speaks the same
///     protocol as Supabase's, so the app keeps using the Supabase *data*
///     client ([dataClientProvider]: `.from()`, `.rpc()`), pointed at Neon
///     and sending Neon's sign-in token with every request;
///   * Neon Functions — photos and push notifications ([neonFunctionsProvider]).
late final NeonAuth _auth;
late final SupabaseClient _data;
late final NeonFunctions _functions;

/// Call once at start-up, before runApp.
Future<void> initBackend() async {
  _auth = NeonAuth(
    authUrl: Env.neonAuthUrl,
    returnUrl: Env.neonAuthReturnUrl,
  );
  await _auth.restore();

  _data = SupabaseClient(
    // The Data API lives at <base>/rest/v1, the same layout as Supabase's.
    Env.neonDataApiUrl.replaceFirst(RegExp(r'/rest/v1/?$'), ''),
    // No API key is needed: every request carries a sign-in or guest token.
    'unused',
    accessToken: _auth.dataApiToken,
    httpClient: NeonDataApiHttpClient(http.Client()),
  );

  _functions = NeonFunctions(
    auth: _auth,
    mediaUrl: Env.neonMediaUrl,
    pushUrl: Env.neonPushUrl,
  );
}

/// Adapts the Supabase data client's requests to Neon's Data API, which is
/// stricter about headers than Supabase's server:
///   * the client writes `Prefer: ,return=representation` (a leading comma)
///     when it asks for the saved row back — Neon rejects that, so the
///     header is cleaned up;
///   * the unused Supabase `apikey` header is dropped.
class NeonDataApiHttpClient extends http.BaseClient {
  NeonDataApiHttpClient(this._inner);
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.remove('apikey');
    final prefer = request.headers['prefer'] ?? request.headers['Prefer'];
    if (prefer != null) {
      request.headers
        ..remove('prefer')
        ..remove('Prefer');
      final cleaned = cleanPreferHeader(prefer);
      if (cleaned.isNotEmpty) request.headers['Prefer'] = cleaned;
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

/// "  ,return=representation, ,count=exact" -> "return=representation,count=exact"
String cleanPreferHeader(String value) => value
    .split(',')
    .map((p) => p.trim())
    .where((p) => p.isNotEmpty)
    .join(',');

final neonAuthProvider = Provider<NeonAuth>((ref) => _auth);

final dataClientProvider = Provider<SupabaseClient>((ref) => _data);

final neonFunctionsProvider = Provider<NeonFunctions>((ref) => _functions);

final authStateChangesProvider = StreamProvider<AuthChange>((ref) {
  return ref.watch(neonAuthProvider).changes;
});

/// The signed-in person, or null for guests. Rebuilds on sign-in/out.
final currentAuthUserProvider = Provider<AppUser?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(neonAuthProvider).currentUser;
});

/// The signed-in person's id, for repositories; null for guests.
String? currentUserId() => _auth.currentUser?.id;

/// Same, for actions only signed-in people can take.
String requireUserId() {
  final id = _auth.currentUser?.id;
  if (id == null) throw NeonAuthException('Not signed in', sessionInvalid: true);
  return id;
}
