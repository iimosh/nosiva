import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/messaging_repository.dart';
import '../domain/message.dart';

/// Realtime messages for a conversation (oldest→newest).
final messagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
  return ref.watch(messagingRepositoryProvider).messageStream(conversationId);
});

/// Locally-held optimistic messages not yet confirmed by the realtime stream.
final _pendingProvider =
    StateProvider.family<List<Message>, String>((ref, _) => []);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final uid = ref.read(currentAuthUserProvider)!.id;
    final pendingNotifier = ref.read(_pendingProvider(widget.conversationId).notifier);

    // Optimistic: show immediately with a temp id.
    final optimistic = Message(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderId: uid,
      body: text,
      createdAt: DateTime.now(),
    );
    pendingNotifier.state = [...pendingNotifier.state, optimistic];

    try {
      await ref.read(messagingRepositoryProvider).sendMessage(
            conversationId: widget.conversationId,
            body: text,
          );
    } catch (e) {
      // Roll back the optimistic bubble.
      pendingNotifier.state = pendingNotifier.state
          .where((m) => m.id != optimistic.id)
          .toList();
      if (mounted) context.showError('Message failed — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentAuthUserProvider)?.id;
    final stream = ref.watch(messagesStreamProvider(widget.conversationId));
    final pending = ref.watch(_pendingProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: stream.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.hotPink)),
              error: (e, _) => ErrorStateView(message: '$e'),
              data: (messages) {
                // Merge confirmed + still-pending optimistic messages.
                final confirmedBodies = messages.map((m) => m.body).toSet();
                final merged = [
                  ...messages,
                  ...pending.where((p) => !confirmedBodies.contains(p.body)),
                ];
                if (merged.isEmpty) {
                  return const EmptyStateView(
                    emoji: '👋',
                    title: 'Say hi!',
                    message: 'Start the conversation — ask about size, fit, anything.',
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: merged.length,
                  itemBuilder: (_, i) {
                    final m = merged[i];
                    return _Bubble(message: m, isMine: m.senderId == uid);
                  },
                );
              },
            ),
          ),
          _Composer(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});
  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.hotPink
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: isMine ? Colors.white : theme.colorScheme.onSurface),
            ),
            if (message.createdAt != null)
              Text(
                Formatters.chatTimestamp(message.createdAt!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isMine
                      ? Colors.white70
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            // TODO: image sharing via image_picker → Storage → message.image_url
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onPressed: () =>
                  context.showSnack('Image sharing — TODO 📷'),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(hintText: 'Message…'),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            CircleAvatar(
              backgroundColor: AppColors.hotPink,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
