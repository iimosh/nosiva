import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../data/account_repository.dart';

/// Confirms and performs permanent account deletion. The user must type
/// DELETE so it can't be triggered by an accidental tap.
Future<void> showDeleteAccountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteAccountDialog(),
  );
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  static const _confirmWord = 'DELETE';
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await ref.read(accountRepositoryProvider).deleteAccount();
      if (!mounted) return;
      context.showSuccess(context.l10n.accountDeleted);
      Navigator.of(context).pop();
    } on OpenOrdersException {
      if (!mounted) return;
      context.showError(context.l10n.deleteAccountOpenOrders);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      context.showError(context.l10n.deleteAccountFailed('$e'));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _controller.text.trim() == _confirmWord && !_busy;
    return AlertDialog(
      title: Text(context.l10n.deleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.deleteAccountBody),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            enabled: !_busy,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: context.l10n.deleteAccountTypeToConfirm,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: canDelete ? _delete : null,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.error),
                )
              : Text(
                  context.l10n.deleteAccountConfirm,
                  style: TextStyle(
                      color: canDelete ? AppColors.error : null),
                ),
        ),
      ],
    );
  }
}
