import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loaded once in main() before the app starts, so the router can read
/// saved flags synchronously on the very first redirect.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in main()');
});

/// Whether this device has already been past the welcome screen. After that
/// the app opens straight onto the feed, signed in or not.
class WelcomeSeenController extends Notifier<bool> {
  static const _key = 'welcome_seen';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

final welcomeSeenProvider =
    NotifierProvider<WelcomeSeenController, bool>(WelcomeSeenController.new);
