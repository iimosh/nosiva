import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/favorites_repository.dart';

/// Holds the set of favorited listing ids and toggles them optimistically.
class FavoritesController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.watch(favoritesRepositoryProvider).fetchFavoriteIds();
  }

  bool isFavorited(String listingId) =>
      state.valueOrNull?.contains(listingId) ?? false;

  /// Optimistically flips the heart, then syncs with Supabase. Reverts on error.
  Future<void> toggle(String listingId) async {
    final repo = ref.read(favoritesRepositoryProvider);
    final current = {...(state.valueOrNull ?? <String>{})};
    final wasFavorited = current.contains(listingId);

    // Optimistic update
    if (wasFavorited) {
      current.remove(listingId);
    } else {
      current.add(listingId);
    }
    state = AsyncValue.data(current);

    try {
      if (wasFavorited) {
        await repo.remove(listingId);
      } else {
        await repo.add(listingId);
      }
    } catch (_) {
      // Revert on failure
      final reverted = {...(state.valueOrNull ?? <String>{})};
      if (wasFavorited) {
        reverted.add(listingId);
      } else {
        reverted.remove(listingId);
      }
      state = AsyncValue.data(reverted);
      rethrow;
    }
  }
}

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, Set<String>>(
        FavoritesController.new);
