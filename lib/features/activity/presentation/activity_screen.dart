import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          title: const Text('Activity'),
          actions: [
            TextButton(
              onPressed: () =>
                  ref.read(notificationsRepositoryProvider).markAllRead(),
              child: const Text('Mark all read'),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.hotPink,
            indicatorColor: AppColors.hotPink,
            tabs: [
              Tab(text: 'Alerts'),
              Tab(text: 'Buying'),
              Tab(text: 'Selling'),
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
