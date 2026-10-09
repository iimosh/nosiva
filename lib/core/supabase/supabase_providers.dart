import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'secure_auth_storage.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      localStorage: SecureSupabaseLocalStorage(),
      pkceAsyncStorage: SecureSupabaseAsyncStorage(),
    ),
  );
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// The current Supabase auth [User], or null when signed out.
/// Rebuilds whenever [authStateChangesProvider] emits.
final currentAuthUserProvider = Provider<User?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

/// True only while the current session is a password-recovery session
/// (i.e. the user just opened a reset-password email link). Opening that
/// link signs them in, so without this the router would treat it as a
/// normal sign-in and send them straight to the home feed instead of
/// letting them set a new password. Flips back to false automatically once
/// updatePassword() succeeds and fires its own auth-state event.
final passwordRecoveryProvider = Provider<bool>((ref) {
  final event = ref.watch(authStateChangesProvider).valueOrNull?.event;
  return event == AuthChangeEvent.passwordRecovery;
});
