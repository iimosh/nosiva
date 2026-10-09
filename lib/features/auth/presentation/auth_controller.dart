import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';
import '../data/auth_repository.dart';

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

      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        username: trimmedUsername,
      );
      final user = res.user;
      if (res.session != null && user != null) {
        // Signed in straight away (email confirmation off).
        await profileRepo.createInitial(id: user.id, username: trimmedUsername);
        result = SignUpResult.signedIn;
      } else {
        // Email confirmation is on: there is no session yet, so the profile
        // can't be written from the app. It's created from the username in
        // the user metadata (database trigger, or on first sign-in).
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

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_auth.signOut);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
