import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/onboarding_screen.dart';
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
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/profile/presentation/current_profile_provider.dart';
import '../../features/profile/presentation/follow_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/user_profile_screen.dart';
import '../../shell/main_shell.dart';
import '../supabase/supabase_providers.dart';
import 'app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authStateChangesProvider, (_, __) => refresh.value++);
  ref.listen(currentProfileProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(currentAuthUserProvider);
      final loc = state.matchedLocation;
      const authRoutes = {AppRoutes.welcome, AppRoutes.signIn, AppRoutes.signUp};
      final isAuthRoute = authRoutes.contains(loc);
      final isSplash = loc == AppRoutes.splash;

      if (user == null) {
        return isAuthRoute ? null : AppRoutes.welcome;
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
          if (isAuthRoute || isSplash || loc == AppRoutes.onboarding) {
            return AppRoutes.home;
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
                builder: (_, __) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'listing/:id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) =>
                        ListingDetailScreen(listingId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.activity, builder: (_, __) => const ActivityScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sell,
                builder: (_, __) => const CreateListingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.inbox, builder: (_, __) => const InboxScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen())],
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
        path: AppRoutes.orders,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const OrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NotificationsScreen(),
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
    ],
  );
});
