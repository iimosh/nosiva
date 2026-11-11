import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/neon/neon_auth.dart';

/// The "current password" typed to confirm a sensitive change was wrong.
class WrongPasswordException implements Exception {}

enum OAuthProvider { google }

/// Thin wrapper over Neon Auth. Keeps auth concerns out of the UI.
class AuthRepository {
  AuthRepository(this._auth);
  final NeonAuth _auth;

  AppUser? get currentUser => _auth.currentUser;

  /// The chosen username is sent as the account's name; the database creates
  /// the profile from it (migration 0020). Returns false when the address
  /// has to be confirmed before the account can be used.
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) =>
      _auth.signUp(email: email, password: password, username: username);

  Future<void> signIn({required String email, required String password}) =>
      _auth.signIn(email: email, password: password);

  Future<void> signInWithOAuth(OAuthProvider provider) => switch (provider) {
        OAuthProvider.google => _auth.signInWithGoogle(),
      };

  Future<void> signOut() => _auth.signOut();

  /// Emails a new 6-digit code that confirms the address.
  Future<void> sendVerificationCode(String email) =>
      _auth.sendVerificationCode(email);

  /// Confirms the address with the emailed code, and signs the person in.
  Future<void> verifyEmail({required String email, required String code}) =>
      _auth.verifyEmail(email: email, code: code);

  /// Emails a 6-digit code for resetting the password.
  Future<void> sendPasswordResetCode(String email) =>
      _auth.sendPasswordResetCode(email);

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _auth.resetPassword(email: email, code: code, newPassword: newPassword);

  /// Whether the account signs in with a password (false for Google-only
  /// accounts, which have no password to change).
  Future<bool> hasPassword() => _auth.hasPassword();

  /// Changes the password of the signed-in account. The current password is
  /// required, so someone holding an unlocked phone can't lock the owner out.
  /// Every other device signed in to the account is signed out.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on NeonAuthException catch (e) {
      if (e.code == 'INVALID_PASSWORD' || e.code == 'INVALID_EMAIL_OR_PASSWORD') {
        throw WrongPasswordException();
      }
      rethrow;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(neonAuthProvider));
});

/// Whether the signed-in account has a password (Settings shows "Change
/// password" only then).
final hasPasswordProvider = FutureProvider.autoDispose<bool>((ref) {
  if (ref.watch(currentAuthUserProvider) == null) return false;
  return ref.watch(authRepositoryProvider).hasPassword();
});
