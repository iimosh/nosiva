import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import 'auth_controller.dart';
import 'widgets/oauth_buttons.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      context.showSuccess('Welcome back bestie 💖');
    } else {
      context.showError('Couldn’t sign you in — check your details');
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
                Text('Welcome back 👋', style: theme.textTheme.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text('Your closet missed you.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xl),
                NosivaTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: 'Password',
                  hint: '••••••••',
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
                  label: 'Sign in',
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
                    onPressed: () => context.pushReplacement(AppRoutes.signUp),
                    child: const Text('New here? Create an account'),
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
