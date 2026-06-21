import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../listings/data/listings_repository.dart';
import '../../listings/domain/listing.dart';
import '../../listings/domain/listing_enums.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';

/// Recent listings of any status (incl. hidden) for the admin moderation view.
final adminListingsProvider = FutureProvider<List<Listing>>((ref) {
  return ref.watch(listingsRepositoryProvider).fetchAllRecent();
});

/// All users, for the admin Users tab.
final adminUsersProvider = FutureProvider<List<Profile>>((ref) {
  return ref.watch(profileRepositoryProvider).fetchAll();
});

/// Quick counts for the dashboard header, derived from the lists above.
class AdminStats {
  const AdminStats({
    required this.totalListings,
    required this.hiddenListings,
    required this.totalUsers,
    required this.totalAdmins,
  });

  final int totalListings;
  final int hiddenListings;
  final int totalUsers;
  final int totalAdmins;

  int get activeListings => totalListings - hiddenListings;
}

final adminStatsProvider = Provider<AsyncValue<AdminStats>>((ref) {
  final listings = ref.watch(adminListingsProvider);
  final users = ref.watch(adminUsersProvider);

  if (listings.isLoading || users.isLoading) return const AsyncValue.loading();
  if (listings.hasError) {
    return AsyncValue.error(listings.error!, listings.stackTrace!);
  }
  if (users.hasError) {
    return AsyncValue.error(users.error!, users.stackTrace!);
  }

  final l = listings.value ?? const [];
  final u = users.value ?? const [];
  return AsyncValue.data(AdminStats(
    totalListings: l.length,
    hiddenListings:
        l.where((e) => e.statusEnum == ListingStatus.hidden).length,
    totalUsers: u.length,
    totalAdmins: u.where((e) => e.isAdmin).length,
  ));
});

class AdminController {
  AdminController(this._listings, this._profiles);
  final ListingsRepository _listings;
  final ProfileRepository _profiles;

  Future<void> hide(String id) => _listings.setStatus(id, ListingStatus.hidden);
  Future<void> unhide(String id) => _listings.setStatus(id, ListingStatus.active);
  Future<void> delete(String id) => _listings.deleteListing(id);

  Future<void> promote(String userId) => _profiles.setRole(userId, 'admin');
  Future<void> demote(String userId) => _profiles.setRole(userId, 'user');
}

final adminControllerProvider = Provider<AdminController>((ref) {
  return AdminController(
    ref.watch(listingsRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  );
});
