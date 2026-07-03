import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n_extensions.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../features/messaging/presentation/inbox_screen.dart';
import '../features/offers/data/offers_repository.dart';
import '../features/orders/data/orders_repository.dart';
import '../features/profile/presentation/current_profile_provider.dart';

final sellResetSignalProvider = StateProvider<int>((ref) => 0);

final sellFormDirtyProvider = StateProvider<bool>((ref) => false);

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  Future<void> _go(BuildContext context, WidgetRef ref, int index) async {
    final leavingSell = shell.currentIndex == 2 && index != 2;
    if (leavingSell && ref.read(sellFormDirtyProvider)) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.discardListingTitle),
          content: Text(context.l10n.discardListingBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.keepEditing),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                context.l10n.discard,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (discard != true) return;
      ref.read(sellFormDirtyProvider.notifier).state = false;
    }
    if (index == 2) ref.read(sellResetSignalProvider.notifier).state++;
    if (index == 3) ref.invalidate(conversationsProvider);
    if (index == 4) ref.read(currentProfileProvider.notifier).reload();
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    ref.watch(inboxRealtimeProvider); // keep the live inbox subscription open
    ref.watch(profileRealtimeProvider); // live follower/following counts
    final unreadMessages = ref.watch(unreadCountProvider);
    final unreadOrders = ref.watch(unreadOrderActivityCountProvider);
    final unreadOffers = ref.watch(unreadOfferActivityCountProvider);
    final unreadActivity = unreadOrders + unreadOffers;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: AppShadows.soft(AppColors.plum),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: context.l10n.home,
                  selected: shell.currentIndex == 0,
                  onTap: () => _go(context, ref, 0),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: context.l10n.activity,
                  selected: shell.currentIndex == 1,
                  badgeCount: unreadActivity,
                  onTap: () => _go(context, ref, 1),
                ),
                _SellButton(onTap: () => _go(context, ref, 2)),
                _NavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: context.l10n.inbox,
                  selected: shell.currentIndex == 3,
                  badgeCount: unreadMessages,
                  onTap: () => _go(context, ref, 3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: context.l10n.me,
                  selected: shell.currentIndex == 4,
                  onTap: () => _go(context, ref, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        selected ? AppColors.hotPink : theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              backgroundColor: AppColors.hotPink,
              label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _SellButton extends StatelessWidget {
  const _SellButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: AppShadows.soft(AppColors.hotPink),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
