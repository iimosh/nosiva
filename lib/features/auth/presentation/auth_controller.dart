import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';
import '../data/auth_repository.dart';

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

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await _auth.signUp(email: email.trim(), password: password);
      final user = res.user;
      if (user != null) {
        // Create the profile row immediately so onboarding can update it.
        await ref
            .read(profileRepositoryProvider)
            .createInitial(id: user.id, username: username.trim());
      }
    });
    return !state.hasError;
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
