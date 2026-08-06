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
import '../../../core/widgets/nosiva_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../listings/domain/listing_enums.dart';
import '../../listings/domain/listing_l10n.dart';
import '../../listings/presentation/controllers/feed_controller.dart';
import '../../listings/presentation/controllers/listing_detail_provider.dart';
import '../../messaging/data/messaging_repository.dart';
import '../../profile/domain/profile.dart';
import '../../profile/presentation/user_profile_screen.dart' show userProfileProvider;
import '../../reviews/data/reviews_repository.dart';
import '../../reviews/domain/review.dart';
import '../../reviews/presentation/widgets/star_rating.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';

// autoDispose: same reasoning as listingDetailProvider — without it, an
// order viewed earlier in the session stays cached, so re-opening it later
// (e.g. from the activity list after its status changed) can show stale data.
final orderProvider = FutureProvider.autoDispose.family<Order, String>(
    (ref, id) => ref.watch(ordersRepositoryProvider).fetchById(id));

const _statusFlow = [
  OrderStatus.pending,
  OrderStatus.paid,
  OrderStatus.shipped,
  OrderStatus.delivered,
];

Color statusColor(OrderStatus s) => switch (s) {
      OrderStatus.pending => AppColors.sun,
      OrderStatus.paid => AppColors.lilac,
      OrderStatus.shipped => AppColors.lilac,
      OrderStatus.delivered => AppColors.mint,
      OrderStatus.cancelled => AppColors.error,
    };

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  String? _markedReadOrderId;

  void _markRead(String orderId) {
    if (_markedReadOrderId == orderId) return;
    _markedReadOrderId = orderId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await ref.read(ordersRepositoryProvider).markRead(orderId);
        ref.invalidate(buyerOrdersProvider);
        ref.invalidate(sellerOrdersProvider);
      } catch (_) {
        // Reading state is helpful, but it should not block the order screen.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.orderDetails)),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.hotPink)),
        error: (e, _) => ErrorStateView(
          message: '$e',
          onRetry: () => ref.invalidate(orderProvider(widget.orderId)),
        ),
        data: (order) {
          _markRead(order.id);
          return _Body(order: order);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.order});
  final Order order;

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    OrderStatus next, {
    bool confirm = false,
  }) async {
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.cancelOrder),
          content: Text(context.l10n.cancelOrderConfirm),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.keepEditing)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.cancelOrder,
                  style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await ref
          .read(ordersRepositoryProvider)
          .updateStatus(order.id, next.value);
      ref.invalidate(orderProvider(order.id));
      ref.invalidate(buyerOrdersProvider);
      ref.invalidate(sellerOrdersProvider);
      ref.invalidate(feedControllerProvider);
      ref.invalidate(listingDetailProvider(order.listingId));
      ref.invalidate(sellerListingsProvider(order.sellerId));
      if (context.mounted) context.showSuccess(context.l10n.orderUpdated);
    } catch (e) {
      if (context.mounted) context.showError(context.l10n.actionFailed('$e'));
    }
  }

  Future<void> _message(BuildContext context, WidgetRef ref, String userId) async {
    try {
      final convo = await ref
          .read(messagingRepositoryProvider)
          .getOrCreateDirectConversation(userId);
      if (context.mounted) context.push(AppRoutes.chatPath(convo.id));
    } catch (e) {
      if (context.mounted) context.showError(context.l10n.startChatFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentAuthUserProvider)?.id;
    final isSeller = myId == order.sellerId;
    final other = myId == null ? null : order.counterparty(myId);
    final listing = order.listing;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _StatusCard(order: order),
        const SizedBox(height: AppSpacing.md),
        if (listing != null)
          _Card(
            onTap: () => context.push(AppRoutes.listingDetailPath(listing.id)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: listing.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: listing.coverImageUrl!, fit: BoxFit.cover)
                        : const ColoredBox(color: AppColors.blush),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.title,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(Formatters.price(order.total),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.berry)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (other != null)
          _Card(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.blush,
                  backgroundImage: other.avatarUrl != null
                      ? CachedNetworkImageProvider(other.avatarUrl!)
                      : null,
                  child: other.avatarUrl == null
                      ? const Icon(Icons.person_outline_rounded,
                          color: AppColors.hotPink)
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isSeller ? context.l10n.buyer : context.l10n.seller,
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(other.nameOrHandle,
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  tooltip: context.l10n.messageUser,
                  onPressed: () => _message(context, ref, other.id),
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline_rounded),
                  tooltip: context.l10n.profile,
                  onPressed: () => context.push(AppRoutes.userPath(other.id)),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        _InfoRow(
          icon: Icons.local_shipping_outlined,
          label: context.l10n.shippingAddress,
          value: order.shippingAddress ?? '—',
        ),
        if (order.createdAt != null)
          _InfoRow(
            icon: Icons.event_outlined,
            label: context.l10n.orderedLabel,
            value: Formatters.timeAgo(order.createdAt!),
          ),
        _InfoRow(
          icon: Icons.payments_outlined,
          label: context.l10n.total,
          value: Formatters.price(order.total),
        ),
        if (order.statusEnum == OrderStatus.delivered && other != null) ...[
          const SizedBox(height: AppSpacing.md),
          _ReviewSection(order: order, other: other),
        ],
        const SizedBox(height: AppSpacing.lg),
        ..._actions(context, ref, isSeller),
      ],
    );
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref, bool isSeller) {
    final status = order.statusEnum;
    final buttons = <Widget>[];

    void add(String label, OrderStatus next,
        {bool danger = false, bool confirm = false}) {
      buttons.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: NosivaButton(
          label: label,
          variant: danger
              ? NosivaButtonVariant.secondary
              : NosivaButtonVariant.gradient,
          onPressed: () => _setStatus(context, ref, next, confirm: confirm),
        ),
      ));
    }

    if (isSeller) {
      switch (status) {
        case OrderStatus.pending:
          add(context.l10n.acceptOrder, OrderStatus.paid);
          add(context.l10n.declineOrder, OrderStatus.cancelled,
              danger: true, confirm: true);
        case OrderStatus.paid:
          add(context.l10n.markShipped, OrderStatus.shipped);
          add(context.l10n.cancelOrder, OrderStatus.cancelled,
              danger: true, confirm: true);
        case OrderStatus.shipped:
          add(context.l10n.markDelivered, OrderStatus.delivered);
        case OrderStatus.delivered:
        case OrderStatus.cancelled:
          break;
      }
    } else {
      switch (status) {
        case OrderStatus.pending:
          add(context.l10n.cancelOrder, OrderStatus.cancelled,
              danger: true, confirm: true);
        case OrderStatus.shipped:
          add(context.l10n.confirmReceived, OrderStatus.delivered);
        case OrderStatus.paid:
        case OrderStatus.delivered:
        case OrderStatus.cancelled:
          break;
      }
    }
    return buttons;
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order.statusEnum;
    final cancelled = status == OrderStatus.cancelled;
    final currentStep = _statusFlow.indexOf(status);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.l10n.status, style: theme.textTheme.bodyMedium),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor(status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(status.localizedLabel(context.l10n),
                    style: theme.textTheme.labelLarge),
              ),
            ],
          ),
          if (!cancelled) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (var i = 0; i < _statusFlow.length; i++) ...[
                  _StepDot(done: i <= currentStep),
                  if (i < _statusFlow.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < currentStep
                            ? AppColors.hotPink
                            : theme.colorScheme.outline,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final s in _statusFlow)
                  Expanded(
                    child: Text(
                      s.localizedLabel(context.l10n),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.hotPink : Theme.of(context).colorScheme.outline,
      ),
      child: done
          ? const Icon(Icons.check, size: 11, color: Colors.white)
          : null,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.hotPink),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadii.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

class _ReviewSection extends ConsumerWidget {
  const _ReviewSection({required this.order, required this.other});

  final Order order;
  final Profile other;

  Future<void> _openSheet(BuildContext context, WidgetRef ref, Review? existing) async {
    final result = await showModalBottomSheet<({int rating, String? comment})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(other: other, existing: existing),
    );
    if (result == null) return;

    try {
      await ref.read(reviewsRepositoryProvider).upsertReview(
            orderId: order.id,
            revieweeId: other.id,
            rating: result.rating,
            comment: result.comment,
          );
      ref.invalidate(myReviewForOrderProvider(order.id));
      ref.invalidate(userReviewsProvider(other.id));
      ref.invalidate(userProfileProvider(other.id));
      if (context.mounted) {
        context.showSuccess(
          existing == null ? context.l10n.reviewSubmitted : context.l10n.reviewUpdated,
        );
      }
    } catch (e) {
      if (context.mounted) context.showError(context.l10n.reviewFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reviewAsync = ref.watch(myReviewForOrderProvider(order.id));

    return reviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (review) {
        if (review == null) {
          return _Card(
            onTap: () => _openSheet(context, ref, null),
            child: Row(
              children: [
                const Icon(Icons.star_outline_rounded, color: AppColors.hotPink),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(context.l10n.leaveReview,
                      style: theme.textTheme.titleMedium),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          );
        }
        return _Card(
          onTap: () => _openSheet(context, ref, review),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StarRating(rating: review.rating, size: 18),
                    if (review.comment?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(review.comment!, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(context.l10n.editReview,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: AppColors.hotPink)),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.other, required this.existing});

  final Profile other;
  final Review? existing;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _comment.text = widget.existing?.comment ?? '';
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      context.showError(context.l10n.pickRating);
      return;
    }
    Navigator.of(context).pop((
      rating: _rating,
      comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
    ));
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.rateUser(widget.other.nameOrHandle),
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.yourRating, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          StarRating(
            rating: _rating,
            size: 32,
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: AppSpacing.md),
          NosivaTextField(
            hint: context.l10n.reviewCommentHint,
            controller: _comment,
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: AppSpacing.lg),
          NosivaButton(
            label: widget.existing == null
                ? context.l10n.submitReview
                : context.l10n.updateReview,
            variant: NosivaButtonVariant.gradient,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
