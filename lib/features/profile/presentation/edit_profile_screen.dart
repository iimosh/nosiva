import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';
import 'avatar_actions.dart';
import 'current_profile_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/shimmer_box.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _location = TextEditingController();

  Profile? _initial;
  bool _saving = false;

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  void _seed(Profile profile) {
    if (_initial?.id == profile.id) return;
    _initial = profile;
    _displayName.text = profile.displayName ?? '';
    _username.text = profile.username;
    _bio.text = profile.bio ?? '';
    _location.text = profile.location ?? '';
  }

  String? _clean(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return context.l10n.usernameRequired;
    if (username.length < 3) return context.l10n.usernameTooShort;
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return context.l10n.usernameInvalid;
    }
    return null;
  }

  Future<void> _save() async {
    final profile = _initial;
    if (profile == null || !_formKey.currentState!.validate()) return;

    final username = _username.text.trim();
    setState(() => _saving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      if (username != profile.username &&
          !await repo.usernameAvailable(username)) {
        if (mounted) context.showError(context.l10n.usernameTaken);
        return;
      }

      final updated = await repo.updateProfile(
        id: profile.id,
        username: username,
        displayName: _clean(_displayName.text),
        bio: _clean(_bio.text),
        location: _clean(_location.text),
      );
      ref.read(currentProfileProvider.notifier).set(updated);
      if (!mounted) return;
      context.showSuccess(context.l10n.profileUpdated);
      context.pop();
    } catch (e) {
      if (mounted) context.showError(context.l10n.profileUpdateFailed(friendlyError(context.l10n, e)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.editProfile)),
      body: profileAsync.when(
        loading: () => const FormSkeleton(),
        error: (e, _) => Center(child: Text(friendlyError(context.l10n, e))),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text(context.l10n.noProfileFound));
          }
          _seed(profile);
          return SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          EditableAvatar(profile: profile, radius: 52),
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
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(context.l10n.basicInfo),
                    NosivaTextField(
                      label: context.l10n.displayNameOptional,
                      hint: context.l10n.displayNameHint,
                      controller: _displayName,
                      maxLength: 60,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        return Validators.minLength(text, 2, context.l10n);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    NosivaTextField(
                      label: context.l10n.username,
                      hint: context.l10n.usernameHint,
                      controller: _username,
                      maxLength: 30,
                      prefixIcon: Icons.alternate_email_rounded,
                      validator: _validateUsername,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    NosivaTextField(
                      label: context.l10n.bio,
                      hint: context.l10n.bioHint,
                      controller: _bio,
                      maxLines: 4,
                      maxLength: 240,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(context.l10n.location),
                    NosivaTextField(
                      label: context.l10n.locationOptional,
                      hint: context.l10n.cityCountry,
                      controller: _location,
                      maxLength: 120,
                      prefixIcon: Icons.place_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    NosivaButton(
                      label: context.l10n.saveChanges,
                      loading: _saving,
                      variant: NosivaButtonVariant.primary,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: context.palette.emphasis),
      ),
    );
  }
}
