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
      context.showSuccess('Account created! Let’s set up your vibe ✨');
    } else {
      final err = ref.read(authControllerProvider).error;
      context.showError('Couldn’t sign you up — ${err ?? 'try again'}');
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
                Text('Join Nosiva 💕', style: theme.textTheme.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text('Your closet, your rules.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xl),
                NosivaTextField(
                  label: 'Username',
                  hint: 'slaygirl_99',
                  controller: _username,
                  prefixIcon: Icons.tag_rounded,
                  validator: (v) => Validators.minLength(v, 3, field: 'Username'),
                ),
                const SizedBox(height: AppSpacing.md),
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
                  hint: 'at least 8 characters',
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
                  label: 'Create account',
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
                    child: const Text('Already have an account? Sign in'),
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
