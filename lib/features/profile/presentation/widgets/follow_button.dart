import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/nosiva_button.dart';
import '../follow_controller.dart';

class FollowButton extends ConsumerWidget {
  const FollowButton({super.key, required this.userId, this.expand = true});

  final String userId;
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentAuthUserProvider)?.id;
    if (myId == null || myId == userId) return const SizedBox.shrink();

    final following = ref.watch(followControllerProvider).valueOrNull ?? const {};
    final isFollowing = following.contains(userId);

    return NosivaButton(
      label: isFollowing ? context.l10n.following : context.l10n.follow,
      icon: isFollowing ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
      variant: isFollowing
          ? NosivaButtonVariant.secondary
          : NosivaButtonVariant.gradient,
      expand: expand,
      onPressed: () async {
        try {
          await ref.read(followControllerProvider.notifier).toggle(userId);
        } catch (e) {
          if (context.mounted) context.showError('$e');
        }
      },
    );
  }
}
