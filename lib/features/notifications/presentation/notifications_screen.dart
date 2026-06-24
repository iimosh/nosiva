import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';
import '../../listings/domain/listing_enums.dart';

final notificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).stream();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsRepositoryProvider).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: const NotificationsListView(),
    );
  }
}

class NotificationsListView extends ConsumerWidget {
  const NotificationsListView({super.key});

  IconData _icon(NotificationType type) => switch (type) {
        NotificationType.message => Icons.chat_bubble_outline_rounded,
        NotificationType.offer => Icons.local_offer_outlined,
        NotificationType.sale => Icons.shopping_bag_outlined,
        NotificationType.follow => Icons.person_add_alt_1_outlined,
        NotificationType.review => Icons.star_outline_rounded,
        NotificationType.system => Icons.auto_awesome_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsStreamProvider);
    return notifs.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.hotPink)),
      error: (e, _) => ErrorStateView(message: '$e'),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyStateView(
            emoji: '🔔',
            title: 'All caught up!',
            message: 'New messages, offers and sales will pop up here.',
          );
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(indent: 72),
          itemBuilder: (_, i) {
            final n = list[i];
            return ListTile(
              onTap: () =>
                  ref.read(notificationsRepositoryProvider).markRead(n.id),
              leading: CircleAvatar(
                backgroundColor:
                    n.read ? AppColors.surfaceMutedLight : AppColors.blush,
                child: Icon(_icon(n.typeEnum), color: AppColors.hotPink),
              ),
              title: Text(n.title,
                  style: TextStyle(
                      fontWeight:
                          n.read ? FontWeight.w400 : FontWeight.w700)),
              subtitle: n.body != null ? Text(n.body!) : null,
              trailing: n.createdAt != null
                  ? Text(Formatters.timeAgo(n.createdAt!),
                      style: Theme.of(context).textTheme.bodySmall)
                  : null,
            );
          },
        );
      },
    );
  }
}
