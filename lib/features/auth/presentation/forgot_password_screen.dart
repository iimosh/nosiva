import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../data/auth_repository.dart' show authRepositoryProvider;

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(_email.text.trim());
      if (mounted) {
        setState(() => _sent = true);
        context.showSuccess(context.l10n.resetLinkSent);
      }
    } catch (e) {
      if (mounted) context.showError(context.l10n.resetLinkFailed('$e'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.resetPasswordTitle,
                    style: theme.textTheme.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(context.l10n.resetPasswordSubtitle,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xl),
                NosivaTextField(
                  label: context.l10n.email,
                  hint: context.l10n.emailHint,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: Validators.email,
                  enabled: !_sent,
                ),
                const SizedBox(height: AppSpacing.lg),
                NosivaButton(
                  label: context.l10n.sendResetLink,
                  loading: _submitting,
                  variant: NosivaButtonVariant.gradient,
                  onPressed: _sent ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(context.l10n.backToSignIn),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
