import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/neon/neon_auth.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../data/auth_repository.dart' show authRepositoryProvider;

/// Shown after signing up with email (and when an unconfirmed account tries
/// to sign in): the person types the 6-digit code Neon emailed them. That
/// proves the inbox is theirs, and signs them in — the router then moves on
/// to setting up their profile.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  /// Wait between "send a new code" taps, so nobody runs into the email
  /// sender's limits by tapping repeatedly.
  static const resendWait = Duration(seconds: 30);

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _submitting = false;
  int _resendIn = resendWait.inSeconds; // a code was just sent
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _ticker?.cancel();
    setState(() => _resendIn = resendWait.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyEmail(email: widget.email, code: _code.text.trim());
      if (!mounted) return;
      context.showSuccess(l10n.emailConfirmed);
      // Signed in now: the router takes over (profile set-up). If Neon
      // didn't start a session, sign in with the confirmed account.
      if (ref.read(authRepositoryProvider).currentUser == null) {
        context.go(AppRoutes.signIn);
      }
    } on NeonAuthException catch (e) {
      if (!mounted) return;
      final wrongCode = e.code == 'INVALID_OTP' ||
          e.code == 'OTP_EXPIRED' ||
          e.code == 'TOO_MANY_ATTEMPTS';
      context.showError(wrongCode ? l10n.errorWrongCode : friendlyError(l10n, e));
    } catch (e) {
      if (mounted) context.showError(friendlyError(l10n, e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    final l10n = context.l10n;
    _code.clear();
    _startCountdown();
    try {
      await ref.read(authRepositoryProvider).sendVerificationCode(widget.email);
      if (mounted) context.showSuccess(l10n.newCodeSent);
    } catch (e) {
      if (mounted) context.showError(friendlyError(l10n, e));
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.verifyEmailTitle, style: theme.textTheme.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.verifyEmailSubtitle(widget.email),
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xl),
                NosivaTextField(
                  label: l10n.resetCodeLabel,
                  hint: '123456',
                  controller: _code,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_outlined,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _confirm(),
                  validator: (v) => RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : l10n.resetCodeInvalid,
                ),
                const SizedBox(height: AppSpacing.lg),
                NosivaButton(
                  label: l10n.verifyEmailCta,
                  loading: _submitting,
                  variant: NosivaButtonVariant.primary,
                  onPressed: _confirm,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _resendIn > 0 || _submitting ? null : _resend,
                  child: Text(_resendIn > 0
                      ? l10n.resendCodeIn(_resendIn)
                      : l10n.resendCode),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.verifyEmailSpamHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
