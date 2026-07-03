import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../offers/data/offers_repository.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/presentation/orders_screen.dart';

final activityTabRequestProvider = StateProvider<int?>((ref) => null);
final archivedActivityViewProvider = StateProvider<bool>((ref) => false);

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    final requested = ref.read(activityTabRequestProvider);
    final initial = requested != null && requested >= 0 && requested < 2
        ? requested
        : 0;
    _tab = TabController(length: 2, vsync: this, initialIndex: initial);
    if (requested != null) _consume();
  }

  void _consume() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activityTabRequestProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showArchived = ref.watch(archivedActivityViewProvider);

    ref.listen<int?>(activityTabRequestProvider, (_, next) {
      if (next == null) return;
      if (next >= 0 && next < _tab.length && _tab.index != next) {
        _tab.animateTo(next);
      }
      _consume();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.activity),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(ordersRepositoryProvider).markAllRead();
              await ref.read(offersRepositoryProvider).markAllRead();
              ref.invalidate(buyerOrdersProvider);
              ref.invalidate(sellerOrdersProvider);
              ref.invalidate(archivedBuyerOrdersProvider);
              ref.invalidate(archivedSellerOrdersProvider);
              ref.invalidate(buyerOffersProvider);
              ref.invalidate(sellerOffersProvider);
              ref.invalidate(archivedBuyerOffersProvider);
              ref.invalidate(archivedSellerOffersProvider);
            },
            tooltip: context.l10n.markAllRead,
            icon: const Icon(Icons.remove_red_eye_outlined),
          ),
          IconButton(
            onPressed: () => ref
                .read(archivedActivityViewProvider.notifier)
                .state = !showArchived,
            tooltip: showArchived
                ? context.l10n.hideArchived
                : context.l10n.showArchived,
            icon: Icon(
              showArchived
                  ? Icons.archive_rounded
                  : Icons.archive_outlined,
              color: showArchived ? AppColors.hotPink : null,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.hotPink,
          indicatorColor: AppColors.hotPink,
          tabs: [
            Tab(text: context.l10n.buying),
            Tab(text: context.l10n.selling),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          OrderListView(
            provider:
                showArchived ? archivedBuyerOrdersProvider : buyerOrdersProvider,
            offerProvider:
                showArchived ? archivedBuyerOffersProvider : buyerOffersProvider,
            role: OrderListRole.buyer,
            archived: showArchived,
          ),
          OrderListView(
            provider: showArchived
                ? archivedSellerOrdersProvider
                : sellerOrdersProvider,
            offerProvider: showArchived
                ? archivedSellerOffersProvider
                : sellerOffersProvider,
            role: OrderListRole.seller,
            archived: showArchived,
          ),
        ],
      ),
    );
  }
}
