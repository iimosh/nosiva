import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/neon/neon_auth.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../data/auth_repository.dart' show authRepositoryProvider;

/// Forgot password, in two steps on one screen: the person enters their
/// email and gets a 6-digit code, then enters the code with a new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  bool _codeSent = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetCode(_email.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
      context.showSuccess(l10n.resetCodeSent);
    } catch (e) {
      if (mounted) context.showError(l10n.resetLinkFailed(friendlyError(l10n, e)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _reset() async {
    if (!_resetForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _email.text.trim(),
            code: _code.text.trim(),
            newPassword: _password.text,
          );
      if (!mounted) return;
      context.showSuccess(l10n.passwordResetDone);
      context.go(AppRoutes.signIn);
    } on NeonAuthException catch (e) {
      if (!mounted) return;
      final wrongCode = e.code == 'INVALID_OTP' || e.code == 'OTP_EXPIRED' ||
          e.code == 'TOO_MANY_ATTEMPTS';
      context.showError(wrongCode ? l10n.errorWrongCode : friendlyError(l10n, e));
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

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.resetPasswordTitle, style: theme.textTheme.displayMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(_codeSent ? l10n.resetCodeSent : l10n.resetCodeSubtitle,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xl),
              Form(
                key: _emailForm,
                child: NosivaTextField(
                  label: l10n.email,
                  hint: l10n.emailHint,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: (v) => Validators.email(v, l10n),
                  enabled: !_codeSent,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!_codeSent)
                NosivaButton(
                  label: l10n.sendResetCode,
                  loading: _submitting,
                  variant: NosivaButtonVariant.primary,
                  onPressed: _sendCode,
                )
              else
                Form(
                  key: _resetForm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NosivaTextField(
                        label: l10n.resetCodeLabel,
                        hint: '123456',
                        controller: _code,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.pin_outlined,
                        maxLength: 6,
                        textInputAction: TextInputAction.next,
                        validator: (v) => RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '')
                            ? null
                            : l10n.resetCodeInvalid,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NosivaTextField(
                        label: l10n.newPassword,
                        hint: l10n.passwordSignupHint,
                        controller: _password,
                        obscureText: _obscure,
                        prefixIcon: Icons.lock_reset_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.password(v, l10n),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NosivaTextField(
                        label: l10n.confirmNewPassword,
                        hint: l10n.passwordDotsHint,
                        controller: _confirm,
                        obscureText: _obscure,
                        prefixIcon: Icons.lock_reset_rounded,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _reset(),
                        validator: (v) =>
                            v == _password.text ? null : l10n.passwordsDontMatch,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      NosivaButton(
                        label: l10n.updatePasswordCta,
                        loading: _submitting,
                        variant: NosivaButtonVariant.primary,
                        onPressed: _reset,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                _code.clear();
                                _sendCode();
                              },
                        child: Text(l10n.resendCode),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(l10n.backToSignIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
