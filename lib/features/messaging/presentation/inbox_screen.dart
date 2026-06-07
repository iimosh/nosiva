import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/messaging_repository.dart';
import '../domain/conversation.dart';

final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  ref.watch(currentAuthUserProvider);
  return ref.watch(messagingRepositoryProvider).fetchConversations();
});

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convos = ref.watch(conversationsProvider);
    final uid = ref.watch(currentAuthUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: convos.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.hotPink)),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyStateView(
              emoji: '💬',
              title: 'No messages yet',
              message: 'When you message a seller (or get a buyer), it shows up here.',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(indent: 80),
            itemBuilder: (_, i) {
              final c = list[i];
              final other = c.buyerId == uid ? c.seller : c.buyer;
              return ListTile(
                onTap: () => context.push(AppRoutes.chatPath(c.id)),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.blush,
                  child: const Text('💁‍♀️', style: TextStyle(fontSize: 22)),
                ),
                title: Text(other?.nameOrHandle ?? 'Nosiva user'),
                subtitle: Text(c.lastMessage ?? 'Say hi 👋',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: c.lastMessageAt != null
                    ? Text(Formatters.timeAgo(c.lastMessageAt!),
                        style: Theme.of(context).textTheme.bodySmall)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
