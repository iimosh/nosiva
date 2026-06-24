import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/follow_repository.dart';
import '../domain/profile.dart';
import 'user_profile_screen.dart';
import 'widgets/follow_button.dart';

final userFollowersProvider =
    FutureProvider.family<List<Profile>, String>((ref, userId) {
  return ref.watch(followRepositoryProvider).fetchFollowers(userId);
});

final userFollowingProvider =
    FutureProvider.family<List<Profile>, String>((ref, userId) {
  return ref.watch(followRepositoryProvider).fetchFollowing(userId);
});

class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    super.key,
    required this.userId,
    this.initialTab = 0,
  });

  final String userId;
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handle = ref.watch(userProfileProvider(userId)).valueOrNull?.handle;
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(handle ?? ''),
          bottom: TabBar(
            labelColor: AppColors.hotPink,
            indicatorColor: AppColors.hotPink,
            tabs: [
              Tab(text: context.l10n.followers),
              Tab(text: context.l10n.following),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PeopleList(provider: userFollowersProvider(userId)),
            _PeopleList(provider: userFollowingProvider(userId)),
          ],
        ),
      ),
    );
  }
}

class _PeopleList extends ConsumerWidget {
  const _PeopleList({required this.provider});
  final ProviderListenable<AsyncValue<List<Profile>>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(provider);
    return people.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.hotPink)),
      error: (e, _) => ErrorStateView(message: '$e'),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyStateView(emoji: '👤', title: 'Nobody here yet');
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
          itemBuilder: (_, i) => _PersonRow(person: list[i]),
        );
      },
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person});
  final Profile person;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push(AppRoutes.userPath(person.id)),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.blush,
        backgroundImage: person.avatarUrl != null
            ? CachedNetworkImageProvider(person.avatarUrl!)
            : null,
        child: person.avatarUrl == null
            ? const Text('💁‍♀️', style: TextStyle(fontSize: 18))
            : null,
      ),
      title: Text(person.nameOrHandle),
      subtitle: Text(person.handle),
      trailing: FollowButton(userId: person.id, expand: false),
    );
  }
}
