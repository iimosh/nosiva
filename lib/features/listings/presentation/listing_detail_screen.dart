import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
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
import '../domain/listing_l10n.dart';
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

    final facts = <({String label, String value})>[
      (label: context.l10n.category, value: listing.categoryEnum.localizedLabel(context.l10n)),
      (label: context.l10n.condition, value: listing.conditionEnum.localizedLabel(context.l10n)),
      if (listing.size != null) (label: context.l10n.size, value: listing.size!),
      if (listing.color != null) (label: context.l10n.color, value: listing.color!),
      if (listing.brand != null) (label: context.l10n.brand, value: listing.brand!),
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Gallery(listing: listing),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      Formatters.price(listing.price),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: AppColors.berry, fontSize: 30),
                    ),
                  ),
                  _ConditionBadge(condition: listing.conditionEnum),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(listing.title, style: theme.textTheme.headlineSmall),
              if (listing.brand != null) ...[
                const SizedBox(height: 2),
                Text(listing.brand!,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: AppSpacing.sm),
              _MetaRow(listing: listing),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              _FactGrid(facts: facts),

              if (listing.styleTags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(context.l10n.style),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in listing.styleTags)
                      NosivaChip(label: '#${localizedStyleTag(tag, context.l10n)}'),
                  ],
                ),
              ],

              if (listing.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(context.l10n.description),
                const SizedBox(height: AppSpacing.xs),
                _ExpandableText(text: listing.description),
              ],

              const SizedBox(height: AppSpacing.lg),
              _InfoCard(listing: listing),

              if (listing.seller != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(context.l10n.seller),
                const SizedBox(height: AppSpacing.xs),
                _SellerCard(listing: listing),
              ],

              _Rail(
                title: context.l10n.moreFromSeller,
                provider: sellerListingsProvider(listing.sellerId),
                excludeId: listing.id,
              ),
              _Rail(
                title: context.l10n.youMightAlsoLike,
                provider: similarListingsProvider(listing.categoryEnum),
                excludeId: listing.id,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ],
    );
  }
}

class _Gallery extends ConsumerStatefulWidget {
  const _Gallery({required this.listing});
  final Listing listing;

  @override
  ConsumerState<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends ConsumerState<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    if (widget.listing.images.isEmpty) return;
    final urls = widget.listing.images.map((e) => e.imageUrl).toList();
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenGallery(urls: urls, initial: _index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final urls = listing.images.map((e) => e.imageUrl).toList();
    final topPad = MediaQuery.of(context).padding.top;

    final favs = ref.watch(favoritesControllerProvider).valueOrNull ?? const {};
    final liked = favs.contains(listing.id);
    final isAdmin = ref.watch(isAdminProvider);
    final isOwn = ref.watch(currentAuthUserProvider)?.id == listing.sellerId;

    return SizedBox(
      height: 440,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _openFullscreen,
              child: urls.isEmpty
                  ? Container(
                      color: AppColors.blush,
                      alignment: Alignment.center,
                      child: const Icon(Icons.checkroom_outlined,
                          color: AppColors.hotPink, size: 72),
                    )
                  : PageView.builder(
                      controller: _controller,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemCount: urls.length,
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: urls[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const ColoredBox(color: AppColors.blush),
                        errorWidget: (_, __, ___) => const ColoredBox(
                          color: AppColors.blush,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
            ),
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 14,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('${_index + 1}/${urls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),

          if (urls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 7,
                    width: active ? 20 : 7,
                    decoration: BoxDecoration(
                      color: active ? AppColors.hotPink : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),
          Positioned(
            top: topPad + 4,
            left: 4,
            right: 4,
            child: Row(
              children: [
                const _CircleBackButton(),
                const Spacer(),
                _CircleIcon(
                  icon: Icons.ios_share_rounded,
                  onTap: () => context.showSnack(context.l10n.shareTodo),
                ),
                const SizedBox(width: AppSpacing.xs),
                if (isAdmin && !isOwn) ...[
                  _ModerationButton(listing: listing),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: HeartButton(
                    liked: liked,
                    onTap: () => ref
                        .read(favoritesControllerProvider.notifier)
                        .toggle(listing.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenGallery extends StatelessWidget {
  const _FullscreenGallery({required this.urls, required this.initial});
  final List<String> urls;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: urls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(imageUrl: urls[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _ConditionBadge extends StatelessWidget {
  const _ConditionBadge({required this.condition});
  final ItemCondition condition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 14, color: AppColors.mint),
          const SizedBox(width: 4),
          Text(condition.localizedLabel(context.l10n),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;
    final items = <Widget>[
      _meta(Icons.remove_red_eye_outlined, '${listing.viewCount}', style),
      _meta(Icons.favorite_border_rounded, '${listing.favoriteCount}', style),
      if (listing.createdAt != null)
        _meta(Icons.schedule_rounded, Formatters.timeAgo(listing.createdAt!),
            style),
      if (listing.location != null)
        _meta(Icons.place_outlined, listing.location!, style),
    ];
    return Wrap(spacing: AppSpacing.md, runSpacing: 4, children: items);
  }

  Widget _meta(IconData icon, String text, TextStyle? style) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: style?.color),
          const SizedBox(width: 3),
          Text(text, style: style),
        ],
      );
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.facts});
  final List<({String label, String value})> facts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.card,
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text(facts[i].label,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const Spacer(),
                  Text(facts[i].value, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLong = widget.text.length > 160;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            maxLines: _expanded ? null : 4,
            overflow: _expanded ? null : TextOverflow.ellipsis,
          ),
        ),
        if (isLong)
          TextButton(
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? context.l10n.readLess : context.l10n.readMore),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        children: [
          _row(context, Icons.local_shipping_outlined, context.l10n.shipping,
              listing.location != null
                  ? context.l10n.shipsFrom(listing.location!)
                  : context.l10n.calculatedAtCheckout),
          const SizedBox(height: AppSpacing.sm),
          _row(context, Icons.shield_outlined, context.l10n.buyerProtection,
              context.l10n.buyerProtectionBody),
          const SizedBox(height: AppSpacing.sm),
          _row(context, Icons.replay_outlined, context.l10n.returns,
              context.l10n.returnsBody),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String title, String body) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.hotPink),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              Text(body, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
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
                    ? const Icon(Icons.person_outline_rounded,
                        color: AppColors.hotPink, size: 24)
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
                    const Icon(Icons.star_rounded,
                        size: 16, color: AppColors.sun),
                    const SizedBox(width: 2),
                    Text(
                      '${seller.ratingAvg.toStringAsFixed(1)} · ${context.l10n.followersCount(seller.followerCount)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends ConsumerWidget {
  const _Rail({
    required this.title,
    required this.provider,
    required this.excludeId,
  });

  final String title;
  final ProviderListenable<AsyncValue<List<Listing>>> provider;
  final String excludeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(provider).valueOrNull ?? const [];
    final filtered = items.where((l) => l.id != excludeId).take(10).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(title),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => _MiniListingCard(listing: filtered[i]),
          ),
        ),
      ],
    );
  }
}

class _MiniListingCard extends StatelessWidget {
  const _MiniListingCard({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push(AppRoutes.listingDetailPath(listing.id)),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadii.field,
              child: SizedBox(
                height: 150,
                width: 140,
                child: listing.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: listing.coverImageUrl!, fit: BoxFit.cover)
                    : const ColoredBox(color: AppColors.blush),
              ),
            ),
            const SizedBox(height: 4),
            Text(Formatters.price(listing.price),
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.berry)),
            Text(listing.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      child: IconButton(
        icon: Icon(icon, color: AppColors.plum, size: 20),
        onPressed: onTap,
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
                      label: context.l10n.editListing,
                      icon: Icons.edit_outlined,
                      variant: NosivaButtonVariant.secondary,
                      onPressed: () =>
                          context.push(AppRoutes.editListingPath(listing.id)),
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
                      label: context.l10n.makeOffer,
                      variant: NosivaButtonVariant.secondary,
                      onPressed: () => _makeOffer(context, ref),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: NosivaButton(
                      label: context.l10n.buyNow,
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
      final convo =
          await ref.read(messagingRepositoryProvider).getOrCreateConversation(
                listingId: listing.id,
                sellerId: listing.sellerId,
              );
      if (context.mounted) context.push(AppRoutes.chatPath(convo.id));
    } catch (e) {
      if (context.mounted) context.showError(context.l10n.startChatFailed('$e'));
    }
  }

  void _buyNow(BuildContext context, WidgetRef ref) {
    ref.read(cartControllerProvider.notifier).add(listing);
    context.showSuccess(context.l10n.addedToCart);
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
        context.showSuccess(context.l10n.offerSent);
      }
    } catch (e) {
      if (context.mounted) context.showError(context.l10n.sendOfferFailed('$e'));
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
            Text(context.l10n.makeOfferTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(context.l10n.listedAt(Formatters.price(widget.listing.price)),
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            NosivaTextField(
              label: context.l10n.yourOffer,
              hint: context.l10n.priceHint,
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.payments_outlined,
              validator: Validators.price,
            ),
            const SizedBox(height: AppSpacing.lg),
            NosivaButton(
              label: context.l10n.sendOffer,
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
      if (context.mounted) context.showError(context.l10n.actionFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.read(adminControllerProvider);
    final isHidden = listing.statusEnum == ListingStatus.hidden;

    return CircleAvatar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      child: IconButton(
        tooltip: context.l10n.moderate,
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
                    title: Text(isHidden
                        ? context.l10n.unhideListing
                        : context.l10n.hideListing),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _run(
                        context,
                        ref,
                        () => isHidden
                            ? admin.unhide(listing.id)
                            : admin.hide(listing.id),
                        isHidden
                            ? context.l10n.listingRestored
                            : context.l10n.listingHidden,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                    title: Text(context.l10n.deleteListing),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _run(
                        context,
                        ref,
                        () => admin.delete(listing.id),
                        context.l10n.listingDeleted,
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
