import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_preferences.dart';
import '../../../../core/supabase/supabase_providers.dart';

/// The last few searches, newest first, kept on this phone. Stored per
/// account (or for the guest), so people sharing a phone don't see each
/// other's searches.
class RecentSearches extends Notifier<List<String>> {
  static const _max = 8;

  String get _key =>
      'recent_searches_${ref.read(currentAuthUserProvider)?.id ?? 'guest'}';

  @override
  List<String> build() {
    ref.watch(currentAuthUserProvider);
    return ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];
  }

  void add(String query) {
    final q = query.trim();
    if (q.length < 2) return;
    final next = [
      q,
      ...state.where((s) => s.toLowerCase() != q.toLowerCase()),
    ].take(_max).toList();
    _save(next);
  }

  void remove(String query) => _save(state.where((s) => s != query).toList());

  void clear() => _save(const []);

  void _save(List<String> next) {
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next);
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearches, List<String>>(RecentSearches.new);
