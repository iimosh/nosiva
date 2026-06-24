import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import '../../listings/domain/listing_enums.dart';

final buyerOrdersProvider =
    FutureProvider<List<Order>>((ref) => ref.watch(ordersRepositoryProvider).fetchAsBuyer());
final sellerOrdersProvider =
    FutureProvider<List<Order>>((ref) => ref.watch(ordersRepositoryProvider).fetchAsSeller());

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.orders),
          bottom: TabBar(
            labelColor: AppColors.hotPink,
            indicatorColor: AppColors.hotPink,
            tabs: [Tab(text: context.l10n.buying), Tab(text: context.l10n.selling)],
          ),
        ),
        body: TabBarView(
          children: [
            OrderListView(provider: buyerOrdersProvider),
            OrderListView(provider: sellerOrdersProvider),
          ],
        ),
      ),
    );
  }
}


class OrderListView extends ConsumerWidget {
  const OrderListView({super.key, required this.provider});
  final FutureProvider<List<Order>> provider;

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.pending => AppColors.sun,
        OrderStatus.paid => AppColors.lilac,
        OrderStatus.shipped => AppColors.lilac,
        OrderStatus.delivered => AppColors.mint,
        OrderStatus.cancelled => AppColors.error,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(provider);
    return orders.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.hotPink)),
      error: (e, _) => ErrorStateView(message: '$e'),
      data: (list) {
        if (list.isEmpty) {
          return EmptyStateView(
            emoji: '📦',
            title: context.l10n.noOrders,
            message: context.l10n.ordersEmptyMessage,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final o = list[i];
            final theme = Theme.of(context);
            return Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: o.listing?.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: o.listing!.coverImageUrl!,
                            fit: BoxFit.cover)
                        : const ColoredBox(color: AppColors.blush),
                  ),
                ),
                title: Text(o.listing?.title ?? context.l10n.item,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(Formatters.price(o.total)),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(o.statusEnum).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(o.statusEnum.label,
                      style: theme.textTheme.labelMedium),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
