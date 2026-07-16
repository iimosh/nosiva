import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../profile/domain/profile.dart';
import '../../profile/presentation/user_profile_screen.dart' show peopleSearchProvider;
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

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _startChat(String userId) async {
    try {
      final convo = await ref
          .read(messagingRepositoryProvider)
          .getOrCreateDirectConversation(userId);
      ref.invalidate(conversationsProvider);
      if (mounted) context.push(AppRoutes.chatPath(convo.id));
    } catch (e) {
      if (mounted) context.showError(context.l10n.startChatFailed('$e'));
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final convosAsync = ref.watch(conversationsProvider);
    final uid = ref.watch(currentAuthUserProvider)?.id;
    final query = _query.trim();
    final peopleAsync = query.isEmpty
        ? const AsyncValue<List<Profile>>.data(<Profile>[])
        : ref.watch(peopleSearchProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.inbox)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: NosivaTextField(
              controller: _searchController,
              focusNode: _searchFocus,
              hint: context.l10n.searchConversationsHint,
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _clearSearch,
                    ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: convosAsync.when(
              loading: () => const _InboxSkeleton(),
              error: (e, _) => ErrorStateView(
                message: '$e',
                onRetry: () => ref.invalidate(conversationsProvider),
              ),
              data: (list) {
                final lowerQuery = query.toLowerCase();
                final filtered = lowerQuery.isEmpty
                    ? list
                    : list.where((c) {
                        final other = uid == null ? null : c.otherParticipant(uid);
                        final name = other?.nameOrHandle.toLowerCase() ?? '';
                        final handle = other?.username.toLowerCase() ?? '';
                        return name.contains(lowerQuery) || handle.contains(lowerQuery);
                      }).toList();

                final excludeIds = <String>{
                  if (uid != null) uid,
                  for (final c in filtered)
                    if (uid != null) c.otherParticipant(uid)?.id ?? '',
                };
                final people = (peopleAsync.valueOrNull ?? const <Profile>[])
                    .where((p) => !excludeIds.contains(p.id))
                    .toList();

                if (list.isEmpty && query.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: context.l10n.noMessages,
                    message: context.l10n.noMessagesMessage,
                    actionLabel: context.l10n.findSomeoneToMessage,
                    onAction: () => _searchFocus.requestFocus(),
                  );
                }

                final peopleStillLoading = peopleAsync.isLoading;
                if (query.isNotEmpty &&
                    filtered.isEmpty &&
                    people.isEmpty &&
                    !peopleStillLoading) {
                  return EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: context.l10n.noMatches,
                    message: context.l10n.noMatchesMessage,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    for (final c in filtered)
                      _ConversationTile(
                        conversation: c,
                        uid: uid,
                        onDeleted: () {
                          ref.invalidate(conversationsProvider);
                          context.showSuccess(context.l10n.conversationDeleted);
                        },
                      ),
                    if (query.isNotEmpty && people.isNotEmpty) ...[
                      _SectionHeader(context.l10n.people),
                      for (final p in people)
                        _PersonRow(profile: p, onMessage: () => _startChat(p.id)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: AppColors.plum),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.conversation,
    required this.uid,
    required this.onDeleted,
  });

  final Conversation conversation;
  final String? uid;
  final VoidCallback onDeleted;

  Future<bool> _confirmAndHide(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteConversation),
        content: Text(context.l10n.deleteConversationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    try {
      await ref.read(messagingRepositoryProvider).hideConversation(conversation.id);
      return true;
    } catch (e) {
      if (context.mounted) context.showError('$e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = conversation;
    final other = uid == null ? null : c.otherParticipant(uid!);
    final unread = uid == null ? 0 : c.unreadFor(uid!);
    final theme = Theme.of(context);
    final listing = c.listing;

    return Dismissible(
      key: ValueKey(c.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmAndHide(context, ref),
      onDismissed: (_) => onDeleted(),
      child: ListTile(
        onTap: () => context.push(AppRoutes.chatPath(c.id)),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.blush,
          backgroundImage: other?.avatarUrl != null
              ? CachedNetworkImageProvider(other!.avatarUrl!)
              : null,
          child: other?.avatarUrl == null
              ? const Icon(Icons.person_outline_rounded, color: AppColors.hotPink)
              : null,
        ),
        title: Text(
          other?.nameOrHandle ?? context.l10n.nosivaUser,
          style: unread > 0 ? const TextStyle(fontWeight: FontWeight.w700) : null,
        ),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (listing != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: listing.coverImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: listing.coverImageUrl!,
                              width: 16,
                              height: 16,
                              fit: BoxFit.cover,
                            )
                          : Container(width: 16, height: 16, color: AppColors.blush),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.plumSoft),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              c.lastMessage ?? context.l10n.sayHi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: unread > 0
                  ? TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600)
                  : null,
            ),
          ],
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.hotPink,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.profile, required this.onMessage});
  final Profile profile;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onMessage,
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.blush,
        backgroundImage: profile.avatarUrl != null
            ? CachedNetworkImageProvider(profile.avatarUrl!)
            : null,
        child: profile.avatarUrl == null
            ? const Icon(Icons.person_outline_rounded, color: AppColors.hotPink)
            : null,
      ),
      title: Text(profile.nameOrHandle),
      subtitle: Text(profile.handle),
      trailing: OutlinedButton(
        onPressed: onMessage,
        child: Text(context.l10n.messageUser),
      ),
    );
  }
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(indent: 80),
      itemBuilder: (_, __) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Row(
          children: [
            const ShimmerBox(width: 52, height: 52, radius: 26),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 120, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 180, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
