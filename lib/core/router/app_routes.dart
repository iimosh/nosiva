abstract final class AppRoutes {
  // Auth / onboarding
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const onboarding = '/onboarding';

  // Bottom-nav shell branches
  static const home = '/home';
  static const activity = '/activity';
  static const sell = '/sell';
  static const inbox = '/inbox';
  static const profile = '/profile';

  static const listingDetail = '/listing'; // /listing/:id
  static const createListing = '/create-listing';
  static const editListing = '/edit-listing'; // /edit-listing/:id
  static const favorites = '/favorites';
  static const chat = '/chat'; // /chat/:conversationId
  static const cart = '/cart';
  static const orders = '/orders';
  static const notifications = '/notifications';
  static const editProfile = '/edit-profile';
  static const admin = '/admin';
  static const user = '/user'; // /user/:id (public profile)

  static String listingDetailPath(String id) => '$listingDetail/$id';
  static String editListingPath(String id) => '$editListing/$id';
  static String chatPath(String id) => '$chat/$id';
  static String userPath(String id) => '$user/$id';
}
