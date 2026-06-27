import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/l10n_extensions.dart';
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

final inboxRealtimeProvider = Provider<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return;
  final channel = client
      .channel('inbox:$uid')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'conversations',
        callback: (_) => ref.invalidate(conversationsProvider),
      )
      .subscribe();
  ref.onDispose(() => client.removeChannel(channel));
});

final unreadCountProvider = Provider<int>((ref) {
  final uid = ref.watch(currentAuthUserProvider)?.id;
  if (uid == null) return 0;
  final convos = ref.watch(conversationsProvider).valueOrNull ?? const [];
  return convos.fold<int>(0, (sum, c) => sum + c.unreadFor(uid));
});

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convos = ref.watch(conversationsProvider);
    final uid = ref.watch(currentAuthUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.inbox)),
      body: convos.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.hotPink)),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (list) {
          if (list.isEmpty) {
            return EmptyStateView(
              icon: Icons.chat_bubble_outline_rounded,
              title: context.l10n.noMessages,
              message: context.l10n.noMessagesMessage,
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(indent: 80),
            itemBuilder: (_, i) {
              final c = list[i];
              final other = c.buyerId == uid ? c.seller : c.buyer;
              final unread = uid == null ? 0 : c.unreadFor(uid);
              final theme = Theme.of(context);
              return ListTile(
                onTap: () => context.push(AppRoutes.chatPath(c.id)),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.blush,
                  child: const Icon(Icons.person_outline_rounded,
                      color: AppColors.hotPink),
                ),
                title: Text(
                  other?.nameOrHandle ?? context.l10n.nosivaUser,
                  style: unread > 0
                      ? const TextStyle(fontWeight: FontWeight.w700)
                      : null,
                ),
                subtitle: Text(
                  c.lastMessage ?? context.l10n.sayHi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: unread > 0
                      ? TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600)
                      : null,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (c.lastMessageAt != null)
                      Text(Formatters.timeAgo(c.lastMessageAt!),
                          style: theme.textTheme.bodySmall),
                    if (unread > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: const BoxDecoration(
                          color: AppColors.hotPink,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
