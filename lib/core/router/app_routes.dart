/// Centralized route paths & names. Keep these the single source of truth.
abstract final class AppRoutes {
  // Auth / onboarding
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const onboarding = '/onboarding';

  // Bottom-nav shell branches
  static const home = '/home';
  static const search = '/search';
  static const sell = '/sell';
  static const inbox = '/inbox';
  static const profile = '/profile';

  // Pushed detail routes
  static const listingDetail = '/listing'; // /listing/:id
  static const createListing = '/create-listing';
  static const favorites = '/favorites';
  static const chat = '/chat'; // /chat/:conversationId
  static const cart = '/cart';
  static const orders = '/orders';
  static const notifications = '/notifications';
  static const editProfile = '/edit-profile';
  static const designSystem = '/design-system';

  static String listingDetailPath(String id) => '$listingDetail/$id';
  static String chatPath(String id) => '$chat/$id';
}
