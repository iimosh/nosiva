import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

class CurrentProfile extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final user = ref.watch(currentAuthUserProvider);
    if (user == null) return null;

    final repo = ref.watch(profileRepositoryProvider);
    final existing = await repo.fetchById(user.id);
    if (existing != null) return existing;

    // Email sign-ups carry their chosen username in the user metadata
    // (they had no session to create the profile with at sign-up time).
    final chosen = user.userMetadata?['username'];
    if (chosen is String && RegExp(r'^[A-Za-z0-9_]{3,30}$').hasMatch(chosen)) {
      try {
        return await repo.createInitial(id: user.id, username: chosen);
      } catch (_) {
        // Taken in the meantime — fall through to a generated username.
      }
    }

    final emailLocal = user.email?.split('@').first ?? 'user';
    final slug = _slug(emailLocal);
    // Capped so the result stays within the 30-char username limit.
    final username =
        '${slug.length > 20 ? slug.substring(0, 20) : slug}${user.id.substring(0, 4)}';
    return repo.createInitial(id: user.id, username: username);
  }

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentAuthUserProvider);
      if (user == null) return null;
      return ref.read(profileRepositoryProvider).fetchById(user.id);
    });
  }

  Future<void> reload() async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;
    final profile = await ref.read(profileRepositoryProvider).fetchById(user.id);
    if (profile != null) state = AsyncValue.data(profile);
  }

  void set(Profile profile) => state = AsyncValue.data(profile);

  static String _slug(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
}
final languageChangingProvider = StateProvider<bool>((ref) => false);

final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfile, Profile?>(CurrentProfile.new);

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentProfileProvider).valueOrNull?.isAdmin ?? false;
});

final profileRealtimeProvider = Provider<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return;
  final channel = client
      .channel('profile:$uid')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: uid,
        ),
        callback: (_) => ref.read(currentProfileProvider.notifier).reload(),
      )
      .subscribe();
  ref.onDispose(() => client.removeChannel(channel));
});
