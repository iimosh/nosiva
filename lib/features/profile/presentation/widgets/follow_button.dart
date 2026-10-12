import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/nosiva_button.dart';
import '../../../auth/presentation/guest_prompt.dart';
import '../follow_controller.dart';
import '../../../../core/utils/friendly_error.dart';

class FollowButton extends ConsumerWidget {
  const FollowButton({super.key, required this.userId, this.expand = true});

  final String userId;
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentAuthUserProvider)?.id;
    // Guests see the button too; tapping it asks them to sign in.
    if (myId != null && myId == userId) return const SizedBox.shrink();

    final following = ref.watch(followControllerProvider).valueOrNull ?? const {};
    final isFollowing = following.contains(userId);

    return NosivaButton(
      label: isFollowing ? context.l10n.following : context.l10n.follow,
      icon: isFollowing ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
      variant: isFollowing
          ? NosivaButtonVariant.secondary
          : NosivaButtonVariant.primary,
      expand: expand,
      onPressed: () async {
        if (!ensureSignedIn(context, ref, GuestAction.follow)) return;
        HapticFeedback.lightImpact();
        try {
          await ref.read(followControllerProvider.notifier).toggle(userId);
        } catch (e) {
          if (context.mounted) context.showError(friendlyError(context.l10n, e));
        }
      },
    );
  }
}
