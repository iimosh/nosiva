import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../data/auth_repository.dart' show authRepositoryProvider;

/// Shown when the app opens via a password-reset email link (see
/// passwordRecoveryProvider). Once the password is updated, the router
/// redirects away automatically — no manual navigation from here.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      if (mounted) context.showSuccess(context.l10n.passwordUpdated);
    } catch (e) {
      if (mounted) context.showError(context.l10n.passwordUpdateFailed('$e'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text(context.l10n.setNewPasswordTitle,
                    style: theme.textTheme.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(context.l10n.setNewPasswordSubtitle,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xl),
                NosivaTextField(
                  label: context.l10n.newPassword,
                  hint: context.l10n.passwordSignupHint,
                  controller: _password,
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: context.l10n.confirmNewPassword,
                  hint: context.l10n.passwordDotsHint,
                  controller: _confirm,
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => v == _password.text
                      ? null
                      : context.l10n.passwordsDontMatch,
                ),
                const SizedBox(height: AppSpacing.lg),
                NosivaButton(
                  label: context.l10n.updatePasswordCta,
                  loading: _submitting,
                  variant: NosivaButtonVariant.gradient,
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
