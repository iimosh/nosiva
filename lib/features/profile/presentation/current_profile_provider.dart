import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/live/live_updates.dart';
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

    // Email sign-ups carry their chosen username as the account's name (the
    // database normally creates the profile from it already, migration 0020).
    final chosen = user.name;
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

final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfile, Profile?>(CurrentProfile.new);

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentProfileProvider).valueOrNull?.isAdmin ?? false;
});

/// Keeps the signed-in person's profile fresh (follower counts, ratings):
/// checked every minute while the app is open, and when a notification
/// arrives or the app comes back to the foreground.
final profileLiveProvider = Provider<void>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return;
  final repo = ref.watch(profileRepositoryProvider);
  final sub = ref
      .watch(liveUpdatesProvider)
      .watch(() => repo.fetchById(uid), every: const Duration(minutes: 1))
      .listen((profile) {
    if (profile != null) ref.read(currentProfileProvider.notifier).set(profile);
  }, onError: (_) {});
  ref.onDispose(sub.cancel);
});
