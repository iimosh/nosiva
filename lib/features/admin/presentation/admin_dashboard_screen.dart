import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/state_views.dart';
import '../../listings/domain/listing.dart';
import '../../listings/domain/listing_enums.dart';
import '../../listings/presentation/controllers/feed_controller.dart';
import '../../profile/domain/profile.dart';
import 'admin_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(adminListingsProvider);
    ref.invalidate(adminUsersProvider);
    ref.invalidate(feedControllerProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin 🛡️'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _refresh(ref),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.hotPink,
            indicatorColor: AppColors.hotPink,
            tabs: [
              Tab(text: 'Listings'),
              Tab(text: 'Reports'),
              Tab(text: 'Users'),
            ],
          ),
        ),
        body: Column(
          children: const [
            _StatsHeader(),
            Expanded(
              child: TabBarView(
                children: [_ListingsTab(), _ReportsTab(), _UsersTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsHeader extends ConsumerWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    return stats.maybeWhen(
      data: (s) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
        child: Row(
          children: [
            _StatCard(label: 'Listings', value: '${s.totalListings}', emoji: '🛍️'),
            const SizedBox(width: AppSpacing.xs),
            _StatCard(label: 'Hidden', value: '${s.hiddenListings}', emoji: '🚫'),
            const SizedBox(width: AppSpacing.xs),
            _StatCard(label: 'Users', value: '${s.totalUsers}', emoji: '👥'),
            const SizedBox(width: AppSpacing.xs),
            _StatCard(label: 'Admins', value: '${s.totalAdmins}', emoji: '🛡️'),
          ],
        ),
      ),
      orElse: () => const SizedBox(height: 4),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.emoji});
  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadii.field,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.titleLarge),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ListingsTab extends ConsumerWidget {
  const _ListingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(adminListingsProvider);
    return listings.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.hotPink)),
      error: (e, _) => ErrorStateView(
        message: '$e',
        onRetry: () => ref.invalidate(adminListingsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateView(
            emoji: '🛡️',
            title: 'Nothing to moderate',
            message: 'New listings will show up here as they\'re posted.',
          );
        }
        return RefreshIndicator(
          color: AppColors.hotPink,
          onRefresh: () async => ref.invalidate(adminListingsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _AdminListingTile(listing: items[i]),
          ),
        );
      },
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateView(
      emoji: '🚩',
      title: 'Reports coming soon',
      message: 'User reports of listings & sellers will land here for review.',
    );
  }
}

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    return users.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.hotPink)),
      error: (e, _) => ErrorStateView(
        message: '$e',
        onRetry: () => ref.invalidate(adminUsersProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateView(emoji: '👥', title: 'No users yet');
        }
        return RefreshIndicator(
          color: AppColors.hotPink,
          onRefresh: () async => ref.invalidate(adminUsersProvider),
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
            itemBuilder: (_, i) => _UserTile(user: items[i]),
          ),
        );
      },
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});
  final Profile user;

  Future<void> _changeRole(BuildContext context, WidgetRef ref, bool makeAdmin) async {
    final action = makeAdmin ? 'Make admin' : 'Remove admin';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action?'),
        content: Text(makeAdmin
            ? '${user.nameOrHandle} will get full moderation powers.'
            : '${user.nameOrHandle} will lose admin access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      final admin = ref.read(adminControllerProvider);
      await (makeAdmin ? admin.promote(user.id) : admin.demote(user.id));
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        context.showSuccess(makeAdmin ? 'Promoted to admin 🛡️' : 'Admin removed');
      }
    } catch (e) {
      if (context.mounted) context.showError('Couldn’t update role — $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelf = ref.watch(currentAuthUserProvider)?.id == user.id;

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.blush,
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? const Text('💁‍♀️', style: TextStyle(fontSize: 18))
            : null,
      ),
      title: Text(isSelf ? '${user.nameOrHandle} (you)' : user.nameOrHandle),
      subtitle: Text(user.handle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user.isAdmin) const _RoleBadge(),
          // Can't change your own role
          if (!isSelf)
            PopupMenuButton<bool>(
              tooltip: 'Manage role',
              onSelected: (makeAdmin) => _changeRole(context, ref, makeAdmin),
              itemBuilder: (_) => [
                if (user.isAdmin)
                  const PopupMenuItem(value: false, child: Text('Remove admin'))
                else
                  const PopupMenuItem(value: true, child: Text('Make admin 🛡️')),
              ],
            ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'ADMIN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AdminListingTile extends ConsumerWidget {
  const _AdminListingTile({required this.listing});
  final Listing listing;

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      ref.invalidate(adminListingsProvider);
      ref.invalidate(feedControllerProvider);
      if (context.mounted) context.showSuccess(success);
    } catch (e) {
      if (context.mounted) context.showError('Action failed — $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final admin = ref.read(adminControllerProvider);
    final isHidden = listing.statusEnum == ListingStatus.hidden;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: listing.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: listing.coverImageUrl!, fit: BoxFit.cover)
                    : const ColoredBox(color: AppColors.blush),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium),
                  Text(
                    '${Formatters.price(listing.price)} · ${listing.status}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isHidden ? AppColors.error : null,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isHidden ? 'Unhide' : 'Hide',
              icon: Icon(isHidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => _act(
                context,
                ref,
                () => isHidden ? admin.unhide(listing.id) : admin.hide(listing.id),
                isHidden ? 'Listing restored' : 'Listing hidden',
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () => _confirmDelete(context, ref, admin),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AdminController admin,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('“${listing.title}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await _act(context, ref, () => admin.delete(listing.id), 'Listing deleted');
    }
  }
}
