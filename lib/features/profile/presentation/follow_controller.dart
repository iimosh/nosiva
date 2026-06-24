import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/follow_repository.dart';
import 'user_profile_screen.dart';

class FollowController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.watch(followRepositoryProvider).fetchFollowingIds();
  }

  bool isFollowing(String userId) =>
      state.valueOrNull?.contains(userId) ?? false;

  Future<void> toggle(String userId) async {
    final repo = ref.read(followRepositoryProvider);
    final current = {...(state.valueOrNull ?? <String>{})};
    final wasFollowing = current.contains(userId);

    if (wasFollowing) {
      current.remove(userId);
    } else {
      current.add(userId);
    }
    state = AsyncValue.data(current);

    try {
      if (wasFollowing) {
        await repo.unfollow(userId);
      } else {
        await repo.follow(userId);
      }
      ref.invalidate(userProfileProvider(userId));
    } catch (_) {
      final reverted = {...(state.valueOrNull ?? <String>{})};
      if (wasFollowing) {
        reverted.add(userId);
      } else {
        reverted.remove(userId);
      }
      state = AsyncValue.data(reverted);
      rethrow;
    }
  }
}

final followControllerProvider =
    AsyncNotifierProvider<FollowController, Set<String>>(FollowController.new);
