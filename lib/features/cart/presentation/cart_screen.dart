import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../core/widgets/nosiva_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../orders/data/orders_repository.dart';
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
      context.showError('Add a shipping address first 📦');
      return;
    }

    setState(() => _placing = true);
    try {
      // ============================================================
      // 💳 STRIPE INTEGRATION POINT (stubbed for the MVP)
      // ------------------------------------------------------------
      // In production: create a PaymentIntent via a Supabase Edge
      // Function using your secret key, confirm it client-side with
      // flutter_stripe, and only then create the order rows below.
      //   final intent = await supabase.functions.invoke('create-payment-intent',
      //       body: {'amount': total, 'currency': 'usd'});
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
      if (mounted) {
        context.showSuccess('Order placed! You did that 💖');
        context.go(AppRoutes.orders);
      }
    } catch (e) {
      if (mounted) context.showError('Checkout failed — $e');
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
      appBar: AppBar(title: const Text('Cart 🛍️')),
      body: items.isEmpty
          ? const EmptyStateView(
              emoji: '🛒',
              title: 'Your bag is empty',
              message: 'Add something fabulous and come back ✨',
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
                  label: 'Shipping address',
                  hint: 'Street, City, ZIP, Country',
                  controller: _address,
                  maxLines: 2,
                  prefixIcon: Icons.local_shipping_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SummaryRow(label: 'Subtotal', value: Formatters.price(total)),
                _SummaryRow(label: 'Shipping', value: 'Calculated at checkout'),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  label: 'Total',
                  value: Formatters.price(total),
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                NosivaButton(
                  label: 'Checkout · ${Formatters.price(total)}',
                  loading: _placing,
                  variant: NosivaButtonVariant.gradient,
                  onPressed: _checkout,
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text('💳 Payment is stubbed (Stripe integration point)',
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
                  color: emphasize ? AppColors.hotPink : null)),
        ],
      ),
    );
  }
}
