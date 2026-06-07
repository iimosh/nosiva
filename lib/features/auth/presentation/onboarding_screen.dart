import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../listings/domain/listing_enums.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/current_profile_provider.dart';

/// First-run setup: pick favorite categories, sizes & styles. These seed the
/// home feed and become the user's "vibe tags".
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _displayName = TextEditingController();
  final _location = TextEditingController();
  final _categories = <ListingCategory>{};
  final _sizes = <String>{};
  final _styles = <String>{};
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
                vibeTags: _styles.toList(),
              );
      ref.read(currentProfileProvider.notifier).set(updated);
      // Router redirect picks up `onboarded == true` and lands on home.
    } catch (e) {
      if (mounted) context.showError('Couldn’t save — $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Let’s set your vibe ✨',
                  style: theme.textTheme.displayMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('We’ll use this to curate your feed.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xl),
              NosivaTextField(
                label: 'Display name (optional)',
                hint: 'What should we call you?',
                controller: _displayName,
              ),
              const SizedBox(height: AppSpacing.md),
              NosivaTextField(
                label: 'Location (optional)',
                hint: 'City, Country',
                controller: _location,
                prefixIcon: Icons.place_outlined,
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: 'Favorite categories',
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final c in ListingCategory.values)
                      NosivaChip(
                        label: '${c.emoji} ${c.label}',
                        selected: _categories.contains(c),
                        onTap: () => setState(() => _categories.toggle(c)),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Your sizes',
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final s in kSizes)
                      NosivaChip(
                        label: s,
                        selected: _sizes.contains(s),
                        onTap: () => setState(() => _sizes.toggle(s)),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Styles you love',
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in kStyleTags)
                      NosivaChip(
                        label: tag,
                        selected: _styles.contains(tag),
                        onTap: () => setState(() => _styles.toggle(tag)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              NosivaButton(
                label: 'Start slaying 💖',
                loading: _saving,
                variant: NosivaButtonVariant.gradient,
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        child,
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

extension<T> on Set<T> {
  void toggle(T value) => contains(value) ? remove(value) : add(value);
}
