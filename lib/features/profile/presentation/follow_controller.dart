import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/follow_repository.dart';
import 'current_profile_provider.dart';
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
    _bumpMyFollowingCount(wasFollowing ? -1 : 1);

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
      _bumpMyFollowingCount(wasFollowing ? 1 : -1);
      rethrow;
    }
  }

  void _bumpMyFollowingCount(int delta) {
    final me = ref.read(currentProfileProvider).valueOrNull;
    if (me == null) return;
    final next = (me.followingCount + delta).clamp(0, 1 << 31);
    ref
        .read(currentProfileProvider.notifier)
        .set(me.copyWith(followingCount: next));
  }
}

final followControllerProvider =
    AsyncNotifierProvider<FollowController, Set<String>>(FollowController.new);
