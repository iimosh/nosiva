import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

/// Loads (and lazily creates) the signed-in user's profile.
/// Rebuilds whenever the auth user changes.
class CurrentProfile extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final user = ref.watch(currentAuthUserProvider);
    if (user == null) return null;

    final repo = ref.watch(profileRepositoryProvider);
    final existing = await repo.fetchById(user.id);
    if (existing != null) return existing;

    // OAuth / first-run: derive a username from the email and create the row.
    final emailLocal = user.email?.split('@').first ?? 'bestie';
    final username =
        '${_slug(emailLocal)}${user.id.substring(0, 4)}';
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

  /// Optimistically replace the cached profile (used after edits/onboarding).
  void set(Profile profile) => state = AsyncValue.data(profile);

  static String _slug(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
}

final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfile, Profile?>(CurrentProfile.new);
