import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../orders/presentation/orders_screen.dart';

/// The "Activity" tab: alerts + your orders (buying & selling).
/// Replaces the old Search tab — search now lives on Home.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.activity),
          actions: [
            TextButton(
              onPressed: () =>
                  ref.read(notificationsRepositoryProvider).markAllRead(),
              child: Text(context.l10n.markAllRead),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.hotPink,
            indicatorColor: AppColors.hotPink,
            tabs: [
              Tab(text: context.l10n.alerts),
              Tab(text: context.l10n.buying),
              Tab(text: context.l10n.selling),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const NotificationsListView(),
            OrderListView(provider: buyerOrdersProvider),
            OrderListView(provider: sellerOrdersProvider),
          ],
        ),
      ),
    );
  }
}
