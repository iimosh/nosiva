import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/avatar_actions.dart';
import '../../profile/presentation/current_profile_provider.dart';
import '../../../core/utils/friendly_error.dart';

/// First-run setup: profile photo, display name and location — all optional,
/// so new members get to the feed quickly.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _displayName = TextEditingController();
  final _location = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _displayName.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) return;

    setState(() => _saving = true);
    try {
      final updated =
          await ref.read(profileRepositoryProvider).completeOnboarding(
                id: profile.id,
                displayName: _displayName.text.trim().isEmpty
                    ? null
                    : _displayName.text.trim(),
                location: _location.text.trim().isEmpty
                    ? null
                    : _location.text.trim(),
              );
      ref.read(currentProfileProvider.notifier).set(updated);
      // Router redirect picks up `onboarded == true` and lands on home.
    } catch (e) {
      if (mounted) context.showError(context.l10n.couldNotSave(friendlyError(context.l10n, e)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(context.l10n.onboardingTitle,
                  style: theme.textTheme.displayMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(context.l10n.onboardingSubtitle,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (profile != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Column(
                    children: [
                      EditableAvatar(profile: profile, radius: 44),
                      TextButton(
                        onPressed: () => showAvatarOptions(
                          context,
                          ref,
                          userId: profile.id,
                          hasPhoto: profile.avatarUrl != null,
                        ),
                        child: Text(context.l10n.changePhoto),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              NosivaTextField(
                label: context.l10n.displayNameOptional,
                hint: context.l10n.displayNameHint,
                controller: _displayName,
                maxLength: 60,
              ),
              const SizedBox(height: AppSpacing.md),
              NosivaTextField(
                label: context.l10n.locationOptional,
                hint: context.l10n.cityCountry,
                controller: _location,
                maxLength: 120,
                prefixIcon: Icons.place_outlined,
              ),
              const SizedBox(height: AppSpacing.xl),
              NosivaButton(
                label: context.l10n.continueButton,
                loading: _saving,
                variant: NosivaButtonVariant.primary,
                onPressed: _finish,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
