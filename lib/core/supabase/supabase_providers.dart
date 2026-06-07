import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Initializes the Supabase SDK. Call once during bootstrap.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    // The "anon public" key from the Supabase dashboard. Newer SDKs also accept
    // a `publishableKey` (sb_publishable_…); swap if your project uses that.
    // ignore: deprecated_member_use
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}

/// The shared [SupabaseClient]. Everything DB/Storage/Realtime flows through here.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Streams auth state changes (sign-in, sign-out, token refresh).
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
