import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_repository.dart';
import '../../../core/neon/neon_auth.dart';
import '../data/auth_repository.dart';
import '../../notifications/push_controller.dart';

enum SignUpResult { signedIn, confirmEmail, failed }

/// Drives auth actions and exposes a loading/error state to the UI.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AuthRepository get _auth => ref.read(authRepositoryProvider);

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signIn(email: email.trim(), password: password);
    });
    return !state.hasError;
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    var result = SignUpResult.failed;
    state = await AsyncValue.guard(() async {
      final trimmedUsername = username.trim();
      final profileRepo = ref.read(profileRepositoryProvider);

      // Checked before creating the auth account: otherwise a taken
      // username fails profile creation *after* the login already exists,
      // leaving an orphaned account with no profile behind it.
      if (await profileRepo.isUsernameTaken(trimmedUsername)) {
        throw UsernameTakenException();
      }

      final signedIn = await _auth.signUp(
        email: email.trim(),
        password: password,
        username: trimmedUsername,
      );
      final user = _auth.currentUser;
      if (signedIn && user != null) {
        // Signed in straight away (email confirmation off). The database
        // already created the profile from the username (migration 0020);
        // this only makes sure of it.
        await profileRepo.createInitial(id: user.id, username: trimmedUsername);
        result = SignUpResult.signedIn;
      } else {
        // Email confirmation is on: the profile was created from the
        // username by the database; the account works once confirmed.
        result = SignUpResult.confirmEmail;
      }
    });
    return state.hasError ? SignUpResult.failed : result;
  }

  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _auth.signInWithOAuth(provider));
    return !state.hasError;
  }

  /// Signs in with Google and tells the person if it went wrong (closing the
  /// Google tab on purpose isn't an error).
  Future<void> signInWithOAuthFrom(
    OAuthProvider provider,
    void Function(Object error) onError,
  ) async {
    if (await signInWithOAuth(provider)) return;
    final err = state.error;
    if (err is NeonAuthException && err.cancelled) return;
    if (err != null) onError(err);
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    // While still signed in: stop this phone getting the account's
    // notifications.
    await ref.read(pushControllerProvider.notifier).forgetDevice();
    state = await AsyncValue.guard(_auth.signOut);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
