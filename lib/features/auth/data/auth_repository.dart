import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Thin wrapper over Supabase Auth. Keeps auth concerns out of the UI.
class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  static const oauthRedirectTo = 'com.example.nosiva://login-callback/';

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  /// The chosen username travels as user metadata so the profile can be
  /// created for it even when no session exists yet (email confirmation on).
  /// [oauthRedirectTo] is reused as the confirmation-link target so the link
  /// opens the app instead of a dead web page.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
      emailRedirectTo: oauthRedirectTo,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signInWithOAuth(OAuthProvider provider) {
    return _client.auth.signInWithOAuth(
      provider,
      redirectTo: oauthRedirectTo,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Sends a password-reset email. Reuses [oauthRedirectTo] since it's
  /// already registered with the app's deep-link scheme and already on
  /// Supabase's allow-listed redirect URLs — no separate dashboard config
  /// needed. Opening the link establishes a temporary recovery session,
  /// which [passwordRecoveryProvider] detects to route into the reset flow.
  Future<void> resetPassword(String email) => _client.auth
      .resetPasswordForEmail(email, redirectTo: oauthRedirectTo);

  /// Sets a new password for the current (recovery) session.
  Future<void> updatePassword(String newPassword) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
