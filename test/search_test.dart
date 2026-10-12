import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/storage/app_preferences.dart';
import 'package:nosiva/core/supabase/supabase_providers.dart';
import 'package:nosiva/features/listings/data/listings_repository.dart';
import 'package:nosiva/features/listings/presentation/controllers/recent_searches.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('searchPrefixQuery', () {
    test('every word also matches as the start of a word', () {
      expect(ListingsRepository.searchPrefixQuery('jea'), 'jea:*');
      expect(ListingsRepository.searchPrefixQuery('  red   dre '), 'red:* & dre:*');
      expect(ListingsRepository.searchPrefixQuery('фустан'), 'фустан:*');
    });

    test('symbols can never change the query', () {
      expect(ListingsRepository.searchPrefixQuery("jeans' | !(x) & :* <->"),
          'jeans:* & x:*');
      expect(ListingsRepository.searchPrefixQuery('%_*'), isNull);
      expect(ListingsRepository.searchPrefixQuery(''), isNull);
      expect(ListingsRepository.searchPrefixQuery(null), isNull);
    });

    test('long input is capped at six words', () {
      expect(
        ListingsRepository.searchPrefixQuery('a b c d e f g h')!.split(' & '),
        hasLength(6),
      );
    });
  });

  group('recent searches', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentAuthUserProvider.overrideWithValue(null),
      ]);
    });

    tearDown(() => container.dispose());

    RecentSearches recents() => container.read(recentSearchesProvider.notifier);

    test('newest first, no duplicates, ignores one-letter searches', () {
      recents().add('jeans');
      recents().add('dress');
      recents().add('JEANS');
      recents().add('a');
      expect(container.read(recentSearchesProvider), ['JEANS', 'dress']);
    });

    test('keeps only the last eight and can remove or clear', () {
      for (var i = 0; i < 10; i++) {
        recents().add('item $i');
      }
      expect(container.read(recentSearchesProvider), hasLength(8));
      expect(container.read(recentSearchesProvider).first, 'item 9');

      recents().remove('item 9');
      expect(container.read(recentSearchesProvider).first, 'item 8');

      recents().clear();
      expect(container.read(recentSearchesProvider), isEmpty);
    });
  });
}
