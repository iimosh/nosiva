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
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../listings/data/listings_repository.dart';
import '../../listings/presentation/controllers/feed_controller.dart';
import '../../listings/presentation/controllers/listing_detail_provider.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/presentation/orders_screen.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _address = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    final items = ref.read(cartControllerProvider);
    if (items.isEmpty) return;
    if (_address.text.trim().isEmpty) {
      context.showError(context.l10n.addShippingAddress);
      return;
    }

    setState(() => _placing = true);
    try {
      final sold = await ref
          .read(listingsRepositoryProvider)
          .soldListingIds(items.map((e) => e.id).toList());
      if (sold.isNotEmpty) {
        final cart = ref.read(cartControllerProvider.notifier);
        for (final id in sold) {
          cart.remove(id);
        }
        ref.invalidate(feedControllerProvider);
        if (mounted) {
          context.showError(context.l10n.soldItemsRemoved);
          setState(() => _placing = false);
        }
        return;
      }

      // ============================================================
      // 💳 STRIPE INTEGRATION POINT (stubbed for the MVP)
      // ------------------------------------------------------------
      // In production: create a PaymentIntent via a Supabase Edge
      // Function using your secret key, confirm it client-side with
      // flutter_stripe, and only then create the order rows below.
      //   final intent = await supabase.functions.invoke('create-payment-intent',
      //       body: {'amount': total, 'currency': 'mkd'});
      //   await Stripe.instance.confirmPayment(intent.clientSecret, ...);
      // For now we skip straight to creating "pending" orders.
      // ============================================================
      final repo = ref.read(ordersRepositoryProvider);
      for (final item in items) {
        await repo.createOrder(
          listingId: item.id,
          sellerId: item.sellerId,
          total: item.price,
          shippingAddress: _address.text.trim(),
        );
      }
      ref.read(cartControllerProvider.notifier).clear();
      ref.invalidate(feedControllerProvider);
      ref.invalidate(buyerOrdersProvider);
      for (final item in items) {
        ref.invalidate(listingDetailProvider(item.id));
        ref.invalidate(sellerListingsProvider(item.sellerId));
      }
      if (mounted) {
        context.showSuccess(context.l10n.orderPlaced);
        ref.read(activityTabRequestProvider.notifier).state = 1;
        context.go(AppRoutes.activity);
      }
    } catch (e) {
      if (mounted) context.showError(context.l10n.checkoutFailed('$e'));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartControllerProvider);
    final total = ref.watch(cartControllerProvider.notifier).total;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cart)),
      body: items.isEmpty
          ? EmptyStateView(
              icon: Icons.shopping_bag_outlined,
              title: context.l10n.bagEmpty,
              message: context.l10n.bagEmptyMessage,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final item in items)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: item.coverImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: item.coverImageUrl!,
                                  fit: BoxFit.cover)
                              : const ColoredBox(color: AppColors.blush),
                        ),
                      ),
                      title: Text(item.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(Formatters.price(item.price)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => ref
                            .read(cartControllerProvider.notifier)
                            .remove(item.id),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: context.l10n.shippingAddress,
                  hint: context.l10n.shippingAddressHint,
                  controller: _address,
                  maxLines: 2,
                  prefixIcon: Icons.local_shipping_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SummaryRow(label: context.l10n.subtotal, value: Formatters.price(total)),
                _SummaryRow(label: context.l10n.shipping, value: context.l10n.calculatedAtCheckout),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  label: context.l10n.total,
                  value: Formatters.price(total),
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                NosivaButton(
                  label: context.l10n.checkout(Formatters.price(total)),
                  loading: _placing,
                  variant: NosivaButtonVariant.gradient,
                  onPressed: _checkout,
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(context.l10n.paymentStubbed,
                      style: theme.textTheme.bodySmall),
                ),
              ],
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasize ? theme.textTheme.titleLarge : theme.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value,
              style: style?.copyWith(
                  color: emphasize ? AppColors.berry : null)),
        ],
      ),
    );
  }
}
