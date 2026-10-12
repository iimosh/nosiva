import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/guest_prompt.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/listings/presentation/create_listing_screen.dart';
import '../../features/listings/presentation/edit_listing_screen.dart';
import '../../features/listings/presentation/home_screen.dart';
import '../../features/listings/presentation/listing_detail_screen.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../features/messaging/presentation/inbox_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/profile/presentation/current_profile_provider.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/follow_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/user_profile_screen.dart';
import '../../features/reviews/presentation/reviews_list_screen.dart';
import '../../shell/main_shell.dart';
import '../../shell/scroll_to_top.dart';
import '../storage/app_preferences.dart';
import '../supabase/supabase_providers.dart';
import 'app_routes.dart';
import 'return_after_sign_in.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Screens a guest (not signed in) may open. Everything else sends them to
/// sign-in — so any screen added later is protected unless listed here.
/// The four tabs are listed because their screens show a "sign in" prompt
/// to guests instead of their content (see [GuestGate]).
const _guestPrefixes = [
  AppRoutes.home, // feed, and /home/listing/:id, /home/user/:id
  '${AppRoutes.listingDetail}/',
  '${AppRoutes.user}/',
  '${AppRoutes.followList}/',
  '${AppRoutes.reviews}/',
  AppRoutes.activity,
  AppRoutes.sell,
  AppRoutes.inbox,
  AppRoutes.profile,
];

bool _guestMayOpen(String location) =>
    _guestPrefixes.any((p) => location == p || location.startsWith(p.endsWith('/') ? p : '$p/'));

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authStateChangesProvider, (_, __) => refresh.value++);
  ref.listen(currentProfileProvider, (_, __) => refresh.value++);
  ref.listen(welcomeSeenProvider, (_, __) => refresh.value++);
  ref.listen(introFinishedProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);
  final returnTo = ref.read(returnAfterSignInProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Let the opening animation finish before leaving the splash.
      if (loc == AppRoutes.splash && !ref.read(introFinishedProvider)) {
        return null;
      }

      // A recovery-email link signs the user in, but they must set a new
      // password before doing anything else — check this first so it
      // overrides every other redirect rule below, including "already
      // signed in -> go home".
      if (ref.read(passwordRecoveryProvider)) {
        return loc == AppRoutes.resetPassword ? null : AppRoutes.resetPassword;
      }

      final user = ref.read(currentAuthUserProvider);
      const authRoutes = {
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.forgotPassword,
      };
      final isAuthRoute = authRoutes.contains(loc);
      final isSplash = loc == AppRoutes.splash;

      if (user == null) {
        if (isAuthRoute) return null;
        // First launch on this device: show the welcome screen once.
        if (!ref.read(welcomeSeenProvider)) return AppRoutes.welcome;
        if (isSplash) return AppRoutes.home;
        if (_guestMayOpen(loc)) return null;
        // A protected screen: sign in first, then come back here.
        returnTo.remember(state.uri.toString());
        return AppRoutes.signIn;
      }

      final profile = ref.read(currentProfileProvider);
      return profile.when(
        loading: () => isSplash ? null : AppRoutes.splash,
        error: (_, __) => isSplash ? null : AppRoutes.splash,
        data: (p) {
          if (p == null) return isSplash ? null : AppRoutes.splash;
          if (!p.onboarded) {
            return loc == AppRoutes.onboarding ? null : AppRoutes.onboarding;
          }
          if (loc == AppRoutes.admin && !p.isAdmin) return AppRoutes.home;
          if (isAuthRoute ||
              isSplash ||
              loc == AppRoutes.onboarding ||
              loc == AppRoutes.resetPassword) {
            // Back to where a guest was when they were asked to sign in.
            return returnTo.take() ?? AppRoutes.home;
          }
          return null;
        },
      );
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.signIn, builder: (_, __) => const SignInScreen()),
      GoRoute(path: AppRoutes.signUp, builder: (_, __) => const SignUpScreen()),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) =>
                    const ScrollToTopOnReselect(tab: 0, child: HomeScreen()),
                routes: [
                  GoRoute(
                    path: 'listing/:id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) =>
                        ListingDetailScreen(listingId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'user/:id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) =>
                        UserProfileScreen(userId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.activity,
                builder: (_, __) => const ScrollToTopOnReselect(
                  tab: 1,
                  child: GuestGate(
                    kind: GuestGateKind.activity,
                    child: ActivityScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sell,
                builder: (_, __) => const ScrollToTopOnReselect(
                  tab: 2,
                  child: GuestGate(
                    kind: GuestGateKind.sell,
                    child: CreateListingScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.inbox,
                builder: (_, __) => const ScrollToTopOnReselect(
                  tab: 3,
                  child: GuestGate(
                    kind: GuestGateKind.inbox,
                    child: InboxScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ScrollToTopOnReselect(
                  tab: 4,
                  child: GuestGate(
                    kind: GuestGateKind.profile,
                    child: ProfileScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '${AppRoutes.listingDetail}/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.createListing,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.editListing}/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            EditListingScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.chat}/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ChatScreen(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.cart,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.orderDetail}/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.user}/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            UserProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${AppRoutes.followList}/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => FollowListScreen(
          userId: state.pathParameters['id']!,
          initialTab:
              state.uri.queryParameters['tab'] == 'following' ? 1 : 0,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.reviews}/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ReviewsListScreen(userId: state.pathParameters['id']!),
      ),
    ],
  );
});
