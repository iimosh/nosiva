import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../listings/data/listings_repository.dart';
import '../../listings/domain/listing.dart';
import '../../listings/domain/listing_l10n.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../domain/profile.dart';
import 'avatar_actions.dart';
import 'current_profile_provider.dart';

final myListingsProvider = FutureProvider<List<Listing>>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  if (profile == null) return Future.value(const []);
  return ref.watch(listingsRepositoryProvider).fetchBySeller(profile.id);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isChangingLanguage = ref.watch(languageChangingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.myProfile),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            tooltip: context.l10n.cart,
            onPressed: () => context.push(AppRoutes.cart),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: context.l10n.orders,
            onPressed: () => context.push(AppRoutes.favorites),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: isChangingLanguage
                ? null
                : () async {
                    ref.read(languageChangingProvider.notifier).state = true;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    var currentLanguage = await ref
                        .read(localeControllerProvider.notifier)
                        .getCurrentLocale();

                    if (currentLanguage == Locale('en')) {
                      await ref
                          .read(localeControllerProvider.notifier)
                          .setLocale(LocaleController.macedonian);
                    } else if (currentLanguage == Locale('mk')) {
                      await ref
                          .read(localeControllerProvider.notifier)
                          .setLocale(LocaleController.english);
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.languageChanged)),
                    );
                    ref.read(languageChangingProvider.notifier).state = false;
                  },
          ),
          IconButton(
            tooltip: context.l10n.signOut,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.hotPink),
        ),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (profile) {
          if (profile == null) {
            return EmptyStateView(title: context.l10n.noProfileFound);
          }
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myListings = ref.watch(myListingsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            EditableAvatar(profile: profile, radius: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.nameOrHandle,
                          style: theme.textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.isAdmin) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const _AdminBadge(),
                      ],
                    ],
                  ),
                  Text(profile.handle, style: theme.textTheme.bodyMedium),
                  if (profile.location != null)
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          profile.location!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        if (profile.bio != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(profile.bio!, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(
              label: context.l10n.followers,
              value: '${profile.followerCount}',
              onTap: () =>
                  context.push(AppRoutes.followListPath(profile.id, tab: 0)),
            ),
            _Stat(
              label: context.l10n.following,
              value: '${profile.followingCount}',
              onTap: () =>
                  context.push(AppRoutes.followListPath(profile.id, tab: 1)),
            ),
            _Stat(
              label: context.l10n.rating,
              value: profile.ratingAvg.toStringAsFixed(1),
            ),
          ],
        ),
        if (profile.isAdmin) ...[
          const SizedBox(height: AppSpacing.md),
          _AdminEntryCard(onTap: () => context.push(AppRoutes.admin)),
        ],
        if (profile.vibeTags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in profile.vibeTags)
                NosivaChip(label: '#${localizedStyleTag(tag, context.l10n)}'),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: Text(context.l10n.editProfile),
          onPressed: () => context.push(AppRoutes.editProfile),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(context.l10n.myCloset, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        myListings.when(
          loading: () => const SizedBox(
            height: 200,
            child: ListingGridSkeleton(itemCount: 2),
          ),
          error: (e, _) => ErrorStateView(message: '$e'),
          data: (listings) {
            if (listings.isEmpty) {
              return EmptyStateView(
                icon: Icons.inventory_2_outlined,
                title: context.l10n.closetEmpty,
                message: context.l10n.closetEmptyMessage,
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.54,
              ),
              itemCount: listings.length,
              itemBuilder: (_, i) => ListingCard(listing: listings[i]),
            );
          },
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.titleLarge),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'ADMIN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _AdminEntryCard extends StatelessWidget {
  const _AdminEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadii.card,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: AppRadii.card,
          boxShadow: AppShadows.soft(AppColors.hotPink),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.adminDashboard,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  Text(
                    context.l10n.adminDashboardSubtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
