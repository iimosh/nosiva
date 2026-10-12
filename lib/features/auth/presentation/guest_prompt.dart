import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/return_after_sign_in.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nosiva_button.dart';
import '../../../l10n/app_localizations.dart';

/// Things a guest can try that need an account.
enum GuestAction { buy, offer, message, favorite, follow, report, cart }

/// Call at the start of any action that needs an account. Returns true when
/// signed in; otherwise shows the sign-in prompt and returns false.
///
/// This only spares guests a confusing error — the database refuses all of
/// these actions without a signed-in user regardless.
bool ensureSignedIn(BuildContext context, WidgetRef ref, GuestAction action) {
  if (ref.read(currentAuthUserProvider) != null) return true;
  showGuestPrompt(context, ref, action);
  return false;
}

Future<void> showGuestPrompt(
  BuildContext context,
  WidgetRef ref,
  GuestAction action,
) {
  final router = GoRouter.of(context);
  final here = router.routerDelegate.currentConfiguration.uri.toString();
  final l10n = context.l10n;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: _GuestMessage(
          icon: _actionIcon(action),
          title: _actionTitle(l10n, action),
          body: l10n.guestPromptBody,
          onChoice: (signUp) {
            ref.read(returnAfterSignInProvider).remember(here);
            Navigator.of(sheet).pop();
            router.push(signUp ? AppRoutes.signUp : AppRoutes.signIn);
          },
        ),
      ),
    ),
  );
}

IconData _actionIcon(GuestAction action) => switch (action) {
      GuestAction.buy || GuestAction.cart => Icons.shopping_bag_outlined,
      GuestAction.offer => Icons.local_offer_outlined,
      GuestAction.message => Icons.chat_bubble_outline_rounded,
      GuestAction.favorite => Icons.favorite_border_rounded,
      GuestAction.follow => Icons.person_add_alt_1_outlined,
      GuestAction.report => Icons.flag_outlined,
    };

String _actionTitle(AppLocalizations l10n, GuestAction action) =>
    switch (action) {
      GuestAction.buy => l10n.guestBuyTitle,
      GuestAction.offer => l10n.guestOfferTitle,
      GuestAction.message => l10n.guestMessageTitle,
      GuestAction.favorite => l10n.guestFavoriteTitle,
      GuestAction.follow => l10n.guestFollowTitle,
      GuestAction.report => l10n.guestReportTitle,
      GuestAction.cart => l10n.guestCartTitle,
    };

/// Sections that are personal to an account.
enum GuestGateKind { activity, sell, inbox, profile, following }

/// Shows [child] to signed-in users. Guests see a friendly "sign in to …"
/// screen instead — and [child] is never built for them, so its account-only
/// data is never even requested.
class GuestGate extends ConsumerWidget {
  const GuestGate({super.key, required this.kind, required this.child});

  final GuestGateKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentAuthUserProvider) != null) return child;

    final l10n = context.l10n;
    final (icon, title, body) = switch (kind) {
      GuestGateKind.activity => (
          Icons.receipt_long_rounded,
          l10n.guestActivityTitle,
          l10n.guestActivityBody,
        ),
      GuestGateKind.sell => (
          Icons.add_a_photo_outlined,
          l10n.guestSellTitle,
          l10n.guestSellBody,
        ),
      GuestGateKind.inbox => (
          Icons.chat_bubble_outline_rounded,
          l10n.guestInboxTitle,
          l10n.guestInboxBody,
        ),
      GuestGateKind.profile => (
          Icons.person_outline_rounded,
          l10n.guestProfileTitle,
          l10n.guestProfileBody,
        ),
      GuestGateKind.following => (
          Icons.favorite_border_rounded,
          l10n.guestFollowingTitle,
          l10n.guestFollowingBody,
        ),
    };

    final content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _GuestMessage(
          icon: icon,
          title: title,
          body: body,
          large: true,
          onChoice: (signUp) {
            final router = GoRouter.of(context);
            ref
                .read(returnAfterSignInProvider)
                .remember(router.routerDelegate.currentConfiguration.uri.toString());
            router.push(signUp ? AppRoutes.signUp : AppRoutes.signIn);
          },
        ),
      ),
    );

    // The Following feed sits inside the home screen's tabs; the others are
    // whole tabs of their own.
    if (kind == GuestGateKind.following) return content;
    return Scaffold(body: SafeArea(child: content));
  }
}

class _GuestMessage extends StatelessWidget {
  const _GuestMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.onChoice,
    this.large = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool large;

  /// true = create account, false = sign in.
  final ValueChanged<bool> onChoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final badge = large ? 96.0 : 72.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: badge,
          width: badge,
          decoration: BoxDecoration(
            color: AppColors.hotPink.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.hotPink, size: badge * 0.42),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: large ? theme.textTheme.headlineMedium : theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        NosivaButton(
          label: l10n.createAccount,
          variant: NosivaButtonVariant.primary,
          onPressed: () => onChoice(true),
        ),
        const SizedBox(height: AppSpacing.sm),
        NosivaButton(
          label: l10n.signIn,
          variant: NosivaButtonVariant.secondary,
          onPressed: () => onChoice(false),
        ),
      ],
    );
  }
}
