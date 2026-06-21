import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/heart_button.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_chip.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../admin/presentation/admin_controller.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../favorites/presentation/favorites_controller.dart';
import '../../messaging/data/messaging_repository.dart';
import '../../offers/data/offers_repository.dart';
import '../../profile/presentation/current_profile_provider.dart';
import '../domain/listing.dart';
import '../domain/listing_enums.dart';
import 'controllers/feed_controller.dart';
import 'controllers/listing_detail_provider.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(listingId));

    return Scaffold(
      body: listingAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.hotPink)),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorStateView(
            message: '$e',
            onRetry: () => ref.invalidate(listingDetailProvider(listingId)),
          ),
        ),
        data: (listing) => _DetailBody(listing: listing),
      ),
      bottomNavigationBar: listingAsync.maybeWhen(
        data: (listing) => _ActionBar(listing: listing),
        orElse: () => null,
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favs = ref.watch(favoritesControllerProvider).valueOrNull ?? const {};
    final liked = favs.contains(listing.id);
    final seller = listing.seller;
    final isAdmin = ref.watch(isAdminProvider);
    final isOwn = ref.watch(currentAuthUserProvider)?.id == listing.sellerId;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 420,
          pinned: true,
          backgroundColor: theme.colorScheme.surface,
          leading: const _CircleBackButton(),
          actions: [
            if (isAdmin && !isOwn)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _ModerationButton(listing: listing),
              ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: HeartButton(
                liked: liked,
                onTap: () => ref
                    .read(favoritesControllerProvider.notifier)
                    .toggle(listing.id),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _Carousel(urls: listing.images.map((e) => e.imageUrl).toList()),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Formatters.price(listing.price),
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: AppColors.hotPink, fontSize: 30)),
                const SizedBox(height: AppSpacing.xs),
                Text(listing.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    NosivaChip(label: '${listing.categoryEnum.emoji} ${listing.categoryEnum.label}'),
                    NosivaChip(label: listing.conditionEnum.label, icon: Icons.verified_outlined),
                    if (listing.size != null) NosivaChip(label: 'Size ${listing.size}'),
                    if (listing.brand != null) NosivaChip(label: listing.brand!),
                    if (listing.color != null) NosivaChip(label: listing.color!),
                  ],
                ),
                if (listing.styleTags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Vibe', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final tag in listing.styleTags)
                        NosivaChip(label: '#$tag'),
                    ],
                  ),
                ],
                if (listing.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text('Description', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(listing.description, style: theme.textTheme.bodyLarge),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (seller != null) _SellerCard(listing: listing),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Carousel extends StatelessWidget {
  const _Carousel({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Container(
        color: AppColors.blush,
        alignment: Alignment.center,
        child: const Text('👗', style: TextStyle(fontSize: 64)),
      );
    }
    return PageView(
      children: [
        for (final url in urls)
          CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
      ],
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seller = listing.seller!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.blush,
            backgroundImage: seller.avatarUrl != null
                ? CachedNetworkImageProvider(seller.avatarUrl!)
                : null,
            child: seller.avatarUrl == null
                ? const Text('💁‍♀️', style: TextStyle(fontSize: 22))
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seller.nameOrHandle, style: theme.textTheme.titleMedium),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: AppColors.sun),
                    const SizedBox(width: 2),
                    Text(
                      '${seller.ratingAvg.toStringAsFixed(1)} · ${seller.followerCount} followers',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // TODO: wire follow/unfollow
          NosivaButton(
            label: 'Follow',
            variant: NosivaButtonVariant.secondary,
            expand: false,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.listing});
  final Listing listing;

  bool _isOwn(WidgetRef ref) =>
      ref.read(currentAuthUserProvider)?.id == listing.sellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOwn = _isOwn(ref);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: AppShadows.soft(AppColors.plum),
      ),
      child: SafeArea(
        top: false,
        child: isOwn
            ? Row(
                children: [
                  Expanded(
                    child: NosivaButton(
                      label: 'Edit listing',
                      icon: Icons.edit_outlined,
                      variant: NosivaButtonVariant.secondary,
                      onPressed: () => context.showSnack('Edit — TODO ✏️'),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  IconButton.filledTonal(
                    iconSize: 26,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    onPressed: () => _message(context, ref),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: NosivaButton(
                      label: 'Make offer',
                      variant: NosivaButtonVariant.secondary,
                      onPressed: () => _makeOffer(context, ref),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: NosivaButton(
                      label: 'Buy now',
                      variant: NosivaButtonVariant.gradient,
                      onPressed: () => _buyNow(context, ref),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _message(BuildContext context, WidgetRef ref) async {
    try {
      final convo = await ref.read(messagingRepositoryProvider).getOrCreateConversation(
            listingId: listing.id,
            sellerId: listing.sellerId,
          );
      if (context.mounted) context.push(AppRoutes.chatPath(convo.id));
    } catch (e) {
      if (context.mounted) context.showError('Couldn’t start chat — $e');
    }
  }

  void _buyNow(BuildContext context, WidgetRef ref) {
    ref.read(cartControllerProvider.notifier).add(listing);
    context.showSuccess('Added to cart 🛍️');
    context.push(AppRoutes.cart);
  }

  Future<void> _makeOffer(BuildContext context, WidgetRef ref) async {
    final amount = await showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OfferSheet(listing: listing),
    );
    if (amount == null) return;
    try {
      await ref.read(offersRepositoryProvider).createOffer(
            listingId: listing.id,
            sellerId: listing.sellerId,
            amount: amount,
          );
      if (context.mounted) {
        context.showSuccess('Offer sent! Fingers crossed 🤞');
      }
    } catch (e) {
      if (context.mounted) context.showError('Couldn’t send offer — $e');
    }
  }
}

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({required this.listing});
  final Listing listing;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Make an offer 💌', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text('Listed at ${Formatters.price(widget.listing.price)}',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            NosivaTextField(
              label: 'Your offer',
              hint: '0.00',
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.attach_money_rounded,
              validator: Validators.price,
            ),
            const SizedBox(height: AppSpacing.lg),
            NosivaButton(
              label: 'Send offer',
              variant: NosivaButtonVariant.gradient,
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.of(context).pop(double.parse(_controller.text.trim()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModerationButton extends ConsumerWidget {
  const _ModerationButton({required this.listing});
  final Listing listing;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String success, {
    bool popAfter = false,
  }) async {
    try {
      await action();
      ref.invalidate(listingDetailProvider(listing.id));
      ref.invalidate(feedControllerProvider);
      ref.invalidate(adminListingsProvider);
      if (context.mounted) {
        context.showSuccess(success);
        if (popAfter) context.pop();
      }
    } catch (e) {
      if (context.mounted) context.showError('Action failed — $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.read(adminControllerProvider);
    final isHidden = listing.statusEnum == ListingStatus.hidden;

    return CircleAvatar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      child: IconButton(
        tooltip: 'Moderate',
        icon: const Icon(Icons.shield_outlined, color: AppColors.plum),
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (sheetCtx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(isHidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    title: Text(isHidden ? 'Unhide listing' : 'Hide listing'),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _run(
                        context,
                        ref,
                        () => isHidden
                            ? admin.unhide(listing.id)
                            : admin.hide(listing.id),
                        isHidden ? 'Listing restored' : 'Listing hidden',
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                    title: const Text('Delete listing'),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _run(
                        context,
                        ref,
                        () => admin.delete(listing.id),
                        'Listing deleted',
                        popAfter: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.plum),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
