import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  void set(Profile profile) => state = AsyncValue.data(profile);

  static String _slug(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
}

final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfile, Profile?>(CurrentProfile.new);
