import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';

/// The "current password" typed to confirm a sensitive change was wrong.
class WrongPasswordException implements Exception {}

/// Thin wrapper over Supabase Auth. Keeps auth concerns out of the UI.
class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  static const oauthRedirectTo = 'mk.nosiva.app://login-callback/';

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

  /// Whether the account signs in with an email and password (and so has a
  /// password and email it can change). False for Google-only accounts.
  bool get hasPassword {
    final providers = currentUser?.appMetadata['providers'];
    if (providers is List) return providers.contains('email');
    return currentUser?.appMetadata['provider'] == 'email';
  }

  /// Changes the password of the signed-in account. The current password is
  /// required, so someone holding an unlocked phone can't lock the owner out.
  /// Every other device signed in to the account is signed out afterwards.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _confirmPassword(currentPassword);
    await _client.auth.updateUser(UserAttributes(password: newPassword));
    try {
      await _client.auth.signOut(scope: SignOutScope.others);
    } catch (_) {
      // The password is already changed; a failure here must not say otherwise.
    }
  }

  /// Starts moving the account to [newEmail], after checking the current
  /// password. Returns true when the change still has to be confirmed from
  /// the email Supabase sends; false when it took effect right away.
  Future<bool> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    await _confirmPassword(currentPassword);
    final res = await _client.auth.updateUser(
      UserAttributes(email: newEmail),
      emailRedirectTo: oauthRedirectTo,
    );
    final pending = res.user?.newEmail;
    return pending != null && pending.isNotEmpty;
  }

  /// Checks [password] against the signed-in account using a separate,
  /// short-lived auth client, so the app's own session isn't replaced (which
  /// would fire sign-in events through the whole app). The extra session it
  /// opens is revoked straight away.
  Future<void> _confirmPassword(String password) async {
    final email = currentUser?.email;
    if (email == null || email.isEmpty) throw AuthSessionMissingException();
    final check = GoTrueClient(
      url: '${Env.supabaseUrl}/auth/v1',
      headers: {
        'apikey': Env.supabaseAnonKey,
        'Authorization': 'Bearer ${Env.supabaseAnonKey}',
      },
      autoRefreshToken: false,
      flowType: AuthFlowType.implicit,
    );
    try {
      await check.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      if (e.code == 'invalid_credentials') throw WrongPasswordException();
      rethrow;
    } finally {
      try {
        await check.signOut();
      } catch (_) {}
      check.dispose();
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
