import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../data/auth_repository.dart';

/// Settings → Change email. The password is asked for again, and the new
/// address only takes over once it's confirmed from the email Supabase sends.
class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      final pending = await ref.read(authRepositoryProvider).changeEmail(
            newEmail: _email.text.trim(),
            currentPassword: _password.text,
          );
      if (!mounted) return;
      context.showSuccess(pending ? l10n.emailChangePending : l10n.emailChanged);
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
    final currentEmail = ref.watch(currentAuthUserProvider)?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changeEmail)),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.changeEmailSubtitle(currentEmail),
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xl),
                NosivaTextField(
                  label: l10n.newEmail,
                  hint: l10n.emailHint,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final error = Validators.email(v, l10n);
                    if (error != null) return error;
                    return v!.trim().toLowerCase() == currentEmail.toLowerCase()
                        ? l10n.errorSameEmail
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: l10n.currentPassword,
                  hint: l10n.passwordDotsHint,
                  controller: _password,
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) => (v ?? '').isEmpty
                      ? l10n.validationPasswordRequired
                      : null,
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? context.l10n.showPassword
                        : context.l10n.hidePassword,
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                NosivaButton(
                  label: l10n.changeEmail,
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
