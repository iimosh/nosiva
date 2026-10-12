import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/router/app_routes.dart';
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
import '../../orders/data/delivery_details.dart';
import '../../orders/data/orders_repository.dart';
import 'cart_controller.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/validators.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    // Pre-filled from the last order or offer.
    final saved = ref.read(deliveryDetailsProvider);
    _address.text = saved.address;
    _phone.text = saved.phone;
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    final items = ref.read(cartControllerProvider);
    if (items.isEmpty) return;
    if (_address.text.trim().isEmpty) {
      context.showError(context.l10n.addShippingAddress);
      return;
    }
    if (_phone.text.trim().isEmpty) {
      context.showError(context.l10n.addPhoneNumber);
      return;
    }
    final phone = Validators.normalizePhone(_phone.text);
    if (phone == null) {
      context.showError(context.l10n.invalidPhoneNumber);
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

      // No payment in the app: the buyer pays the courier in cash on
      // delivery. Placing an order sends a request the seller accepts.
      final repo = ref.read(ordersRepositoryProvider);
      final cart = ref.read(cartControllerProvider.notifier);
      // Each item is removed from the cart as soon as its own order is
      // placed, not after the whole batch finishes — so if a later item
      // fails (e.g. someone else bought it first), earlier successful
      // orders aren't left silently sitting in the cart to be re-ordered
      // (and rejected as duplicates) on retry.
      for (final item in items) {
        await repo.createOrder(
          listingId: item.id,
          sellerId: item.sellerId,
          total: item.price,
          shippingAddress: _address.text.trim(),
          buyerPhone: phone,
        );
        cart.remove(item.id);
        ref.invalidate(listingDetailProvider(item.id));
        ref.invalidate(sellerListingsProvider(item.sellerId));
      }
      ref.invalidate(feedControllerProvider);
      ref.invalidate(buyerOrdersProvider);
      await ref
          .read(deliveryDetailsProvider)
          .save(address: _address.text, phone: _phone.text);
      if (mounted) {
        context.showSuccess(context.l10n.orderPlaced);
        ref.read(activityTabRequestProvider.notifier).state = 0;
        context.go(AppRoutes.activity);
      }
    } catch (e) {
      if (mounted) context.showError(context.l10n.checkoutFailed(friendlyError(context.l10n, e)));
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
                                  fit: BoxFit.cover,
                                  memCacheWidth: 300)
                              : ColoredBox(color: context.palette.placeholder),
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
                  maxLength: 300,
                  prefixIcon: Icons.local_shipping_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                NosivaTextField(
                  label: context.l10n.phoneNumber,
                  hint: context.l10n.phoneNumberHint,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(context.l10n.phoneOnlyForSeller,
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.lg),
                _SummaryRow(
                  label: context.l10n.total,
                  value: Formatters.price(total),
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                _CashOnDeliveryNote(theme: theme),
                const SizedBox(height: AppSpacing.lg),
                NosivaButton(
                  label: context.l10n.checkout(Formatters.price(total)),
                  loading: _placing,
                  variant: NosivaButtonVariant.primary,
                  onPressed: _checkout,
                ),
              ],
            ),
    );
  }
}

/// How paying works on Nosiva: cash to the courier, nothing in the app.
class _CashOnDeliveryNote extends StatelessWidget {
  const _CashOnDeliveryNote({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.payments_outlined, color: context.palette.emphasis),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.cashOnDelivery, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(context.l10n.cashOnDeliveryBody, style: theme.textTheme.bodySmall),
              ],
            ),
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
                  color: emphasize ? context.palette.emphasis : null)),
        ],
      ),
    );
  }
}
