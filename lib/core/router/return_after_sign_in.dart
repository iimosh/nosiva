import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';

/// Where to send a guest once they've signed in (or finished onboarding), so
/// tapping "Buy" on a listing as a guest lands them back on that listing
/// instead of the home feed.
class ReturnAfterSignIn {
  String? _path;

  void remember(String location) => _path = _stackable(location);

  /// Returns the remembered path once, then forgets it.
  String? take() {
    final path = _path;
    _path = null;
    return path;
  }

  void clear() => _path = null;

  /// Listing and profile pages are reached by `push` on top of the feed. Going
  /// back to them by URL alone would leave nothing underneath to go back to,
  /// so they're reopened through their copies nested under the home tab.
  static String? _stackable(String location) {
    if (!location.startsWith('/') || location.startsWith('//')) return null;
    if (location.startsWith('${AppRoutes.listingDetail}/') ||
        location.startsWith('${AppRoutes.user}/')) {
      return '${AppRoutes.home}$location';
    }
    return location;
  }
}

final returnAfterSignInProvider = Provider((ref) => ReturnAfterSignIn());
