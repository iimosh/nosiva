import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbars.dart';
import '../data/safety_repository.dart';
import 'report_sheet.dart';

/// Overflow menu with "Report" and "Block / Unblock" for another user.
class UserSafetyMenu extends ConsumerWidget {
  const UserSafetyMenu({super.key, required this.userId, required this.name});

  final String userId;
  final String name;

  Future<void> _toggleBlock(
    BuildContext context,
    WidgetRef ref,
    bool blocked,
  ) async {
    final controller = ref.read(blockedIdsProvider.notifier);
    try {
      if (blocked) {
        await controller.unblock(userId);
        if (context.mounted) context.showSuccess(context.l10n.userUnblocked);
        return;
      }
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.blockUserTitle(name)),
          content: Text(context.l10n.blockUserMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.blockUser,
                  style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await controller.block(userId);
      if (context.mounted) context.showSuccess(context.l10n.userBlocked);
    } catch (e) {
      if (context.mounted) context.showError(context.l10n.blockFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked =
        ref.watch(blockedIdsProvider).valueOrNull?.contains(userId) ?? false;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        if (value == 'report') {
          showReportSheet(context, targetType: 'user', targetId: userId);
        } else {
          _toggleBlock(context, ref, blocked);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'report', child: Text(context.l10n.reportUser)),
        PopupMenuItem(
          value: 'block',
          child: Text(blocked ? context.l10n.unblockUser : context.l10n.blockUser),
        ),
      ],
    );
  }
}
