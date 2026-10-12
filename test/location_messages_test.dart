import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/location/location_service.dart';
import 'package:nosiva/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final mk = lookupAppLocalizations(const Locale('mk'));

  test('every location failure has its own translated message', () {
    for (final reason in LocationFailure.values) {
      final error = LocationException(reason);
      final english = locationErrorMessage(en, error);
      final macedonian = locationErrorMessage(mk, error);
      expect(english, isNotEmpty);
      expect(macedonian, isNot(english), reason: '$reason is not translated');
    }
  });

  test('timeouts and other errors show a friendly message, not raw text', () {
    final message = locationErrorMessage(mk, TimeoutException('gps'));
    expect(message, mk.locationUnavailable);
    expect(message, isNot(contains('TimeoutException')));
  });
}
