import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/heart_button.dart';
import '../../core/widgets/nosiva_button.dart';
import '../../core/widgets/nosiva_chip.dart';
import '../../core/widgets/nosiva_text_field.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../core/widgets/state_views.dart';

/// A live preview of the Nosiva design system — colors, type, components.
class DesignSystemScreen extends ConsumerStatefulWidget {
  const DesignSystemScreen({super.key});

  @override
  ConsumerState<DesignSystemScreen> createState() => _DesignSystemScreenState();
}

class _DesignSystemScreenState extends ConsumerState<DesignSystemScreen> {
  bool _liked = true;
  String? _selectedChip = 'coquette';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System ✨'),
        actions: [
          IconButton(
            icon: Icon(mode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Section(
            title: 'Colors',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: const [
                _Swatch('Hot Pink', AppColors.hotPink),
                _Swatch('Blush', AppColors.blush),
                _Swatch('Cream', AppColors.cream),
                _Swatch('Plum', AppColors.plum),
                _Swatch('Lilac', AppColors.lilac),
                _Swatch('Mint', AppColors.mint),
                _Swatch('Sun', AppColors.sun),
              ],
            ),
          ),
          _Section(
            title: 'Gradient',
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: AppRadii.card,
              ),
              alignment: Alignment.center,
              child: Text('Brand gradient',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white)),
            ),
          ),
          _Section(
            title: 'Typography',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display Large', style: theme.textTheme.displayLarge),
                Text('Headline', style: theme.textTheme.headlineMedium),
                Text('Title Large', style: theme.textTheme.titleLarge),
                Text('Body large — the quick brown fox.',
                    style: theme.textTheme.bodyLarge),
                Text('Body small / muted', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          _Section(
            title: 'Buttons',
            child: Column(
              children: [
                NosivaButton(
                    label: 'Gradient',
                    variant: NosivaButtonVariant.gradient,
                    onPressed: () {}),
                const SizedBox(height: AppSpacing.xs),
                NosivaButton(
                    label: 'Primary', onPressed: () {}),
                const SizedBox(height: AppSpacing.xs),
                NosivaButton(
                    label: 'Secondary',
                    variant: NosivaButtonVariant.secondary,
                    onPressed: () {}),
                const SizedBox(height: AppSpacing.xs),
                NosivaButton(
                    label: 'With icon',
                    icon: Icons.favorite_rounded,
                    onPressed: () {}),
                const SizedBox(height: AppSpacing.xs),
                const NosivaButton(label: 'Loading', loading: true),
                const SizedBox(height: AppSpacing.xs),
                const NosivaButton(label: 'Disabled', onPressed: null),
              ],
            ),
          ),
          _Section(
            title: 'Chips',
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final t in ['Y2K', 'coquette', 'streetwear', 'vintage'])
                  NosivaChip(
                    label: t,
                    selected: _selectedChip == t,
                    onTap: () => setState(() => _selectedChip = t),
                  ),
              ],
            ),
          ),
          _Section(
            title: 'Text field',
            child: const NosivaTextField(
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.alternate_email_rounded,
            ),
          ),
          _Section(
            title: 'Card + heart',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('A soft, rounded card surface.',
                          style: theme.textTheme.bodyLarge),
                    ),
                    HeartButton(
                      liked: _liked,
                      onTap: () => setState(() => _liked = !_liked),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _Section(
            title: 'Loading skeleton',
            child: Row(
              children: const [
                Expanded(child: ShimmerBox(height: 90, radius: AppRadii.xl)),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: ShimmerBox(height: 90, radius: AppRadii.xl)),
              ],
            ),
          ),
          _Section(
            title: 'Empty state',
            child: SizedBox(
              height: 260,
              child: EmptyStateView(
                emoji: '✨',
                title: 'Your closet is empty bestie',
                message: 'List your first piece to get started.',
                actionLabel: 'List an item',
                onAction: () {},
              ),
            ),
          ),
          const _Section(
            title: 'Error state',
            child: SizedBox(
              height: 220,
              child: ErrorStateView(message: 'Something went sideways.'),
            ),
          ),
        ],
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
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        child,
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          width: 72,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
