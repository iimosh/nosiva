import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/domain/offer.dart';
import '../../listings/domain/listing_enums.dart';
import '../../listings/domain/listing_l10n.dart';
import '../../listings/presentation/controllers/feed_controller.dart';
import '../../listings/presentation/controllers/listing_detail_provider.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';

enum OrderListRole { buyer, seller }

final _optimisticArchivedOrdersProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

final _optimisticRestoredOrdersProvider = StateProvider<Map<String, Order>>(
  (ref) => const <String, Order>{},
);

final _optimisticArchivedOffersProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

final _optimisticRestoredOffersProvider = StateProvider<Map<String, Offer>>(
  (ref) => const <String, Offer>{},
);

String _activityKey(OrderListRole role, String orderId) => '${role.name}:$orderId';

class _ActivityEntry {
  _ActivityEntry.order(Order value)
      : offer = null,
        order = value,
        time = value.activityTime;

  _ActivityEntry.offer(Offer value)
      : order = null,
        offer = value,
        time = value.activityTime;

  final Order? order;
  final Offer? offer;
  final DateTime? time;
}

class OrderListView extends ConsumerWidget {
  const OrderListView({
    super.key,
    required this.provider,
    required this.offerProvider,
    required this.role,
    this.archived = false,
  });

  final StreamProvider<List<Order>> provider;
  final StreamProvider<List<Offer>> offerProvider;
  final OrderListRole role;
  final bool archived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(provider);
    final offerAsync = ref.watch(offerProvider);
    final loading = orderAsync.isLoading && !orderAsync.hasValue ||
        offerAsync.isLoading && !offerAsync.hasValue;
    final error = orderAsync.error ?? offerAsync.error;

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.hotPink),
      );
    }
    if (error != null) return ErrorStateView(message: '$error');

    final orderList = orderAsync.valueOrNull ?? const <Order>[];
    final offerList = offerAsync.valueOrNull ?? const <Offer>[];

        final optimisticArchived = ref.watch(_optimisticArchivedOrdersProvider);
        final optimisticRestored = ref.watch(_optimisticRestoredOrdersProvider);
        final optimisticArchivedOffers =
            ref.watch(_optimisticArchivedOffersProvider);
        final optimisticRestoredOffers =
            ref.watch(_optimisticRestoredOffersProvider);
        final restoredForRole = optimisticRestored.entries
            .where((entry) => entry.key.startsWith('${role.name}:'))
            .map((entry) => entry.value);
        final restoredOffersForRole = optimisticRestoredOffers.entries
            .where((entry) => entry.key.startsWith('${role.name}:'))
            .map((entry) => entry.value);
        final visibleOrders = orderList.where((order) {
          final key = _activityKey(role, order.id);
          if (archived) return !optimisticRestored.containsKey(key);
          return !optimisticArchived.contains(key);
        }).toList();
        final visibleOffers = offerList.where((offer) {
          final key = _activityKey(role, offer.id);
          if (archived) return !optimisticRestoredOffers.containsKey(key);
          return !optimisticArchivedOffers.contains(key);
        }).toList();

        if (!archived) {
          for (final order in restoredForRole) {
            final key = _activityKey(role, order.id);
            final alreadyShown = visibleOrders.any((item) => item.id == order.id);
            if (!alreadyShown && !optimisticArchived.contains(key)) {
              visibleOrders.insert(0, order);
            }
          }
          for (final offer in restoredOffersForRole) {
            final key = _activityKey(role, offer.id);
            final alreadyShown = visibleOffers.any((item) => item.id == offer.id);
            if (!alreadyShown && !optimisticArchivedOffers.contains(key)) {
              visibleOffers.insert(0, offer);
            }
          }
        }

        final entries = [
          for (final order in visibleOrders) _ActivityEntry.order(order),
          for (final offer in visibleOffers) _ActivityEntry.offer(offer),
        ]..sort((a, b) {
            final left = a.time;
            final right = b.time;
            if (left == null && right == null) return 0;
            if (left == null) return 1;
            if (right == null) return -1;
            return right.compareTo(left);
          });

        if (entries.isEmpty) {
          return EmptyStateView(
            icon: role == OrderListRole.buyer
                ? Icons.shopping_bag_outlined
                : Icons.storefront_outlined,
            title:
                archived ? context.l10n.noArchivedOrders : context.l10n.noOrders,
            message: archived
                ? context.l10n.noArchivedOrders
                : role == OrderListRole.buyer
                ? context.l10n.buyingEmptyMessage
                : context.l10n.sellingEmptyMessage,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final entry = entries[i];
            final order = entry.order;
            if (order != null) {
              return _OrderActivityCard(
                order: order,
                role: role,
                archived: archived,
              );
            }
            return _OfferActivityCard(
              offer: entry.offer!,
              role: role,
              archived: archived,
            );
          },
        );
  }
}

class _OrderActivityCard extends ConsumerWidget {
  const _OrderActivityCard({
    required this.order,
    required this.role,
    required this.archived,
  });

  final Order order;
  final OrderListRole role;
  final bool archived;

  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.pending => AppColors.sun,
        OrderStatus.paid => AppColors.lilac,
        OrderStatus.shipped => AppColors.lilac,
        OrderStatus.delivered => AppColors.mint,
        OrderStatus.cancelled => AppColors.error,
      };

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    unawaited(_markRead(ref));
    ref.invalidate(buyerOrdersProvider);
    ref.invalidate(sellerOrdersProvider);
    context.push(AppRoutes.orderDetailPath(order.id));
  }

  Future<void> _markRead(WidgetRef ref) async {
    try {
      await ref.read(ordersRepositoryProvider).markRead(order.id);
    } catch (_) {
      // The order can still be opened even if read state cannot be saved.
    }
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    OrderStatus next,
  ) async {
    try {
      await ref.read(ordersRepositoryProvider).updateStatus(order.id, next.value);
      ref.invalidate(buyerOrdersProvider);
      ref.invalidate(sellerOrdersProvider);
      ref.invalidate(archivedBuyerOrdersProvider);
      ref.invalidate(archivedSellerOrdersProvider);
      ref.invalidate(feedControllerProvider);
      ref.invalidate(listingDetailProvider(order.listingId));
      ref.invalidate(sellerListingsProvider(order.sellerId));
      if (context.mounted) context.showSuccess(context.l10n.orderUpdated);
    } catch (e) {
      if (context.mounted) context.showError(context.l10n.actionFailed('$e'));
    }
  }

  void _removeOptimisticArchived(WidgetRef ref, String key) {
    final current = ref.read(_optimisticArchivedOrdersProvider);
    ref.read(_optimisticArchivedOrdersProvider.notifier).state = {
      for (final item in current)
        if (item != key) item,
    };
  }

  void _removeOptimisticRestored(WidgetRef ref, String key) {
    final current = ref.read(_optimisticRestoredOrdersProvider);
    ref.read(_optimisticRestoredOrdersProvider.notifier).state = {
      for (final entry in current.entries)
        if (entry.key != key) entry.key: entry.value,
    };
  }

  void _refreshOrderLists(WidgetRef ref) {
    ref.invalidate(buyerOrdersProvider);
    ref.invalidate(sellerOrdersProvider);
    ref.invalidate(archivedBuyerOrdersProvider);
    ref.invalidate(archivedSellerOrdersProvider);
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final key = _activityKey(role, order.id);
    ref.read(_optimisticArchivedOrdersProvider.notifier).state = {
      ...ref.read(_optimisticArchivedOrdersProvider),
      key,
    };
    _removeOptimisticRestored(ref, key);

    try {
      await ref.read(ordersRepositoryProvider).archive(order.id);
      _refreshOrderLists(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.archived),
              action: SnackBarAction(
                label: context.l10n.undo,
                onPressed: () => _restore(context, ref),
              ),
            ),
          );
      }
      Future<void>.delayed(const Duration(seconds: 1), () {
        _removeOptimisticArchived(ref, key);
      });
    } catch (e) {
      _removeOptimisticArchived(ref, key);
      if (context.mounted) context.showError(context.l10n.actionFailed('$e'));
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final key = _activityKey(role, order.id);
    _removeOptimisticArchived(ref, key);
    ref.read(_optimisticRestoredOrdersProvider.notifier).state = {
      ...ref.read(_optimisticRestoredOrdersProvider),
      key: order,
    };

    try {
      await ref.read(ordersRepositoryProvider).unarchive(order.id);
      _refreshOrderLists(ref);
      if (context.mounted) context.showSuccess(context.l10n.restored);
      Future<void>.delayed(const Duration(seconds: 1), () {
        _removeOptimisticRestored(ref, key);
      });
    } catch (e) {
      _removeOptimisticRestored(ref, key);
      if (context.mounted) context.showError(context.l10n.actionFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(currentAuthUserProvider)?.id;
    final unread = uid != null && order.isUnreadFor(uid);
    final listing = order.listing;
    final other = role == OrderListRole.seller ? order.buyer : order.seller;
    final otherLabel =
        role == OrderListRole.seller ? context.l10n.buyer : context.l10n.seller;
    final status = order.statusEnum;
    final statusColor = _statusColor(status);
    final activityTime = order.activityTime;
    final needsSellerAction =
        role == OrderListRole.seller && status == OrderStatus.pending;
    final activityLabel = status == OrderStatus.pending
        ? context.l10n.newActivity
        : context.l10n.updatedActivity;

    final card = Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      borderRadius: AppRadii.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context, ref),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: unread
                  ? AppColors.hotPink.withValues(alpha: 0.45)
                  : theme.colorScheme.outlineVariant,
            ),
            borderRadius: AppRadii.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderImage(url: listing?.coverImageUrl),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                listing?.title ?? context.l10n.item,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight:
                                      unread ? FontWeight.w800 : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (unread)
                              _ActivityBadge(
                                label: activityLabel,
                                color: AppColors.error,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          Formatters.price(order.total),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.berry,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$otherLabel: ${other?.nameOrHandle ?? context.l10n.nosivaUser}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (needsSellerAction) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _ActivityBadge(
                            label: context.l10n.actionNeeded,
                            color: AppColors.berry,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _StatusChip(
                    label: status.localizedLabel(context.l10n),
                    color: statusColor,
                  ),
                  const Spacer(),
                  if (activityTime != null)
                    Text(
                      status == OrderStatus.pending
                          ? context.l10n
                              .orderedTime(Formatters.timeAgo(activityTime))
                          : context.l10n
                              .updatedTime(Formatters.timeAgo(activityTime)),
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (archived)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: NosivaButton(
                    label: context.l10n.restore,
                    variant: NosivaButtonVariant.secondary,
                    onPressed: () => _restore(context, ref),
                  ),
                )
              else if (role == OrderListRole.seller)
                _SellerActions(order: order, onStatus: _setStatus),
            ],
          ),
        ),
      ),
    );

    if (archived || !order.canArchiveFromActivity) return card;

    return Dismissible(
      key: ValueKey('archive-${role.name}-${order.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _archive(context, ref);
        return false;
      },
      background: _ArchiveBackground(label: context.l10n.archive),
      child: card,
    );
  }
}

class _OfferActivityCard extends ConsumerWidget {
  const _OfferActivityCard({
    required this.offer,
    required this.role,
    required this.archived,
  });

  final Offer offer;
  final OrderListRole role;
  final bool archived;

  Color _statusColor(OfferStatus status) => switch (status) {
        OfferStatus.pending => AppColors.sun,
        OfferStatus.accepted => AppColors.mint,
        OfferStatus.declined => AppColors.error,
        OfferStatus.countered => AppColors.lilac,
        OfferStatus.expired => AppColors.plumFaint,
      };

  String _statusLabel(BuildContext context, OfferStatus status) {
    return switch (status) {
      OfferStatus.pending => role == OrderListRole.seller
          ? context.l10n.newOffer
          : context.l10n.offerPending,
      OfferStatus.accepted => context.l10n.offerAccepted,
      OfferStatus.declined => context.l10n.offerDeclined,
      OfferStatus.countered => context.l10n.updatedActivity,
      OfferStatus.expired => context.l10n.updatedActivity,
    };
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    unawaited(_markRead(ref));
    _refreshOfferLists(ref);
    if (offer.orderId != null && offer.statusEnum == OfferStatus.accepted) {
      context.push(AppRoutes.orderDetailPath(offer.orderId!));
      return;
    }
    context.push(AppRoutes.listingDetailPath(offer.listingId));
  }

  Future<void> _markRead(WidgetRef ref) async {
    try {
      await ref.read(offersRepositoryProvider).markRead(offer.id);
    } catch (_) {
      // The offer can still be opened even if read state cannot be saved.
    }
  }

  void _refreshOfferLists(WidgetRef ref) {
    ref.invalidate(buyerOffersProvider);
    ref.invalidate(sellerOffersProvider);
    ref.invalidate(archivedBuyerOffersProvider);
    ref.invalidate(archivedSellerOffersProvider);
  }

  void _refreshMarketplace(WidgetRef ref) {
    _refreshOfferLists(ref);
    ref.invalidate(buyerOrdersProvider);
    ref.invalidate(sellerOrdersProvider);
    ref.invalidate(archivedBuyerOrdersProvider);
    ref.invalidate(archivedSellerOrdersProvider);
    ref.invalidate(feedControllerProvider);
    ref.invalidate(listingDetailProvider(offer.listingId));
    ref.invalidate(sellerListingsProvider(offer.sellerId));
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    OfferStatus next,
  ) async {
    try {
      await ref.read(offersRepositoryProvider).respond(offer.id, next.value);
      _refreshMarketplace(ref);
      if (context.mounted) {
        context.showSuccess(
          next == OfferStatus.accepted
              ? context.l10n.offerAccepted
              : context.l10n.offerDeclined,
        );
      }
    } catch (e) {
      if (context.mounted) context.showError(context.l10n.actionFailed('$e'));
    }
  }

  void _removeOptimisticArchived(WidgetRef ref, String key) {
    final current = ref.read(_optimisticArchivedOffersProvider);
    ref.read(_optimisticArchivedOffersProvider.notifier).state = {
      for (final item in current)
        if (item != key) item,
    };
  }

  void _removeOptimisticRestored(WidgetRef ref, String key) {
    final current = ref.read(_optimisticRestoredOffersProvider);
    ref.read(_optimisticRestoredOffersProvider.notifier).state = {
      for (final entry in current.entries)
        if (entry.key != key) entry.key: entry.value,
    };
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final key = _activityKey(role, offer.id);
    ref.read(_optimisticArchivedOffersProvider.notifier).state = {
      ...ref.read(_optimisticArchivedOffersProvider),
      key,
    };
    _removeOptimisticRestored(ref, key);

    try {
      await ref.read(offersRepositoryProvider).archive(offer.id);
      _refreshOfferLists(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.archived),
              action: SnackBarAction(
                label: context.l10n.undo,
                onPressed: () => _restore(context, ref),
              ),
            ),
          );
      }
      Future<void>.delayed(const Duration(seconds: 1), () {
        _removeOptimisticArchived(ref, key);
      });
    } catch (e) {
      _removeOptimisticArchived(ref, key);
      if (context.mounted) context.showError(context.l10n.actionFailed('$e'));
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final key = _activityKey(role, offer.id);
    _removeOptimisticArchived(ref, key);
    ref.read(_optimisticRestoredOffersProvider.notifier).state = {
      ...ref.read(_optimisticRestoredOffersProvider),
      key: offer,
    };

    try {
      await ref.read(offersRepositoryProvider).unarchive(offer.id);
      _refreshOfferLists(ref);
      if (context.mounted) context.showSuccess(context.l10n.restored);
      Future<void>.delayed(const Duration(seconds: 1), () {
        _removeOptimisticRestored(ref, key);
      });
    } catch (e) {
      _removeOptimisticRestored(ref, key);
      if (context.mounted) context.showError(context.l10n.actionFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(currentAuthUserProvider)?.id;
    final unread = uid != null && offer.isUnreadFor(uid);
    final listing = offer.listing;
    final other = role == OrderListRole.seller ? offer.buyer : offer.seller;
    final otherLabel =
        role == OrderListRole.seller ? context.l10n.buyer : context.l10n.seller;
    final status = offer.statusEnum;
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(context, status);
    final activityTime = offer.activityTime;
    final needsSellerAction =
        role == OrderListRole.seller && status == OfferStatus.pending;

    final card = Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      borderRadius: AppRadii.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context, ref),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: unread
                  ? AppColors.hotPink.withValues(alpha: 0.45)
                  : theme.colorScheme.outlineVariant,
            ),
            borderRadius: AppRadii.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderImage(url: listing?.coverImageUrl),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                listing?.title ?? context.l10n.item,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight:
                                      unread ? FontWeight.w800 : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (unread)
                              _ActivityBadge(
                                label: statusLabel,
                                color: AppColors.error,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          context.l10n.offeredPrice(
                            Formatters.price(offer.amount),
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.berry,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (listing != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.originalPrice(
                              Formatters.price(listing.price),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$otherLabel: ${other?.nameOrHandle ?? context.l10n.nosivaUser}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (needsSellerAction) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _ActivityBadge(
                            label: context.l10n.actionNeeded,
                            color: AppColors.berry,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _StatusChip(label: statusLabel, color: statusColor),
                  const Spacer(),
                  if (activityTime != null)
                    Text(
                      context.l10n.offeredTime(
                        Formatters.timeAgo(activityTime),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (archived)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: NosivaButton(
                    label: context.l10n.restore,
                    variant: NosivaButtonVariant.secondary,
                    onPressed: () => _restore(context, ref),
                  ),
                )
              else if (needsSellerAction)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: NosivaButton(
                          label: context.l10n.acceptOffer,
                          variant: NosivaButtonVariant.gradient,
                          onPressed: () => _respond(
                            context,
                            ref,
                            OfferStatus.accepted,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: NosivaButton(
                          label: context.l10n.declineOffer,
                          variant: NosivaButtonVariant.secondary,
                          onPressed: () => _respond(
                            context,
                            ref,
                            OfferStatus.declined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (archived || !offer.canArchiveFromActivity) return card;

    return Dismissible(
      key: ValueKey('archive-offer-${role.name}-${offer.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _archive(context, ref);
        return false;
      },
      background: _ArchiveBackground(label: context.l10n.archive),
      child: card,
    );
  }
}

class _SellerActions extends StatelessWidget {
  const _SellerActions({required this.order, required this.onStatus});

  final Order order;
  final Future<void> Function(BuildContext, WidgetRef, OrderStatus) onStatus;

  @override
  Widget build(BuildContext context) {
    final status = order.statusEnum;
    final actions = <({String label, OrderStatus next, bool secondary})>[];

    switch (status) {
      case OrderStatus.pending:
        actions.add((
          label: context.l10n.acceptOrder,
          next: OrderStatus.paid,
          secondary: false,
        ));
        actions.add((
          label: context.l10n.declineOrder,
          next: OrderStatus.cancelled,
          secondary: true,
        ));
      case OrderStatus.paid:
        actions.add((
          label: context.l10n.markShipped,
          next: OrderStatus.shipped,
          secondary: false,
        ));
      case OrderStatus.shipped:
        actions.add((
          label: context.l10n.markDelivered,
          next: OrderStatus.delivered,
          secondary: false,
        ));
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        break;
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, _) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              Expanded(
                child: NosivaButton(
                  label: actions[i].label,
                  variant: actions[i].secondary
                      ? NosivaButtonVariant.secondary
                      : NosivaButtonVariant.gradient,
                  onPressed: () => onStatus(context, ref, actions[i].next),
                ),
              ),
              if (i < actions.length - 1)
                const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderImage extends StatelessWidget {
  const _OrderImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.card,
      child: SizedBox(
        width: 76,
        height: 76,
        child: url != null
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
            : const ColoredBox(color: AppColors.blush),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _ArchiveBackground extends StatelessWidget {
  const _ArchiveBackground({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.berry,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.archive_outlined, color: Colors.white),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
