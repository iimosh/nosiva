import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../orders/presentation/orders_screen.dart';

final activityTabRequestProvider = StateProvider<int?>((ref) => null);

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
    _tab = TabController(length: 3, vsync: this, initialIndex: requested ?? 0);
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
            onPressed: () =>
                ref.read(notificationsRepositoryProvider).markAllRead(),
            tooltip: context.l10n.markAllRead,
            icon: const Icon(Icons.remove_red_eye_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
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
        controller: _tab,
        children: [
          const NotificationsListView(),
          OrderListView(provider: buyerOrdersProvider),
          OrderListView(provider: sellerOrdersProvider),
        ],
      ),
    );
  }
}
