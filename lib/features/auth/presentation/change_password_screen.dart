import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../data/auth_repository.dart';

/// Settings → Change password. Asks for the current password first, so a
/// phone left unlocked can't be used to take the account over.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _password.text,
          );
      if (!mounted) return;
      context.showSuccess(l10n.passwordUpdated);
      context.pop();
    } on WrongPasswordException {
      if (mounted) context.showError(l10n.errorWrongPassword);
    } catch (e) {
      if (mounted) context.showError(friendlyError(l10n, e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final visibility = IconButton(
      tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
      icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
      onPressed: () => setState(() => _obscure = !_obscure),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.changePasswordSubtitle,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xl),
                NosivaTextField(
                  label: l10n.currentPassword,
                  hint: l10n.passwordDotsHint,
                  controller: _current,
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v ?? '').isEmpty
                      ? l10n.validationPasswordRequired
                      : null,
                  suffixIcon: visibility,
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: l10n.newPassword,
                  hint: l10n.passwordSignupHint,
                  controller: _password,
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_reset_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final error = Validators.password(v, l10n);
                    if (error != null) return error;
                    return v == _current.text ? l10n.errorSamePassword : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: l10n.confirmNewPassword,
                  hint: l10n.passwordDotsHint,
                  controller: _confirm,
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_reset_rounded,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) =>
                      v == _password.text ? null : l10n.passwordsDontMatch,
                ),
                const SizedBox(height: AppSpacing.lg),
                NosivaButton(
                  label: l10n.changePassword,
                  loading: _submitting,
                  variant: NosivaButtonVariant.primary,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
