import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import 'auth_controller.dart';
import 'widgets/oauth_buttons.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).signUp(
          email: _email.text,
          password: _password.text,
          username: _username.text,
        );
    if (!mounted) return;
    if (ok) {
      context.showSuccess(context.l10n.accountCreated);
    } else {
      final err = ref.read(authControllerProvider).error;
      context.showError(context.l10n.signUpFailed(err ?? context.l10n.tryAgain));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loading = ref.watch(authControllerProvider).isLoading;

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
                Text(context.l10n.joinNosiva,
                    style: theme.textTheme.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(context.l10n.yourClosetYourRules,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xl),
                NosivaTextField(
                  label: context.l10n.username,
                  hint: context.l10n.usernameHint,
                  controller: _username,
                  prefixIcon: Icons.tag_rounded,
                  validator: (v) => Validators.minLength(v, 3, field: 'Username'),
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: context.l10n.email,
                  hint: context.l10n.emailHint,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: context.l10n.password,
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
                const SizedBox(height: AppSpacing.lg),
                NosivaButton(
                  label: context.l10n.createAccount,
                  loading: loading,
                  variant: NosivaButtonVariant.gradient,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.lg),
                OAuthButtons(
                  onProvider: (p) =>
                      ref.read(authControllerProvider.notifier).signInWithOAuth(p),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: () => context.pushReplacement(AppRoutes.signIn),
                    child: Text(context.l10n.alreadyHaveAccountSignIn),
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
