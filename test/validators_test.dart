import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/utils/validators.dart';
import 'package:nosiva/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final mk = lookupAppLocalizations(const Locale('mk'));

  test('form messages follow the app language', () {
    expect(Validators.email('', mk), mk.validationEmailRequired);
    expect(Validators.email('not-an-email', mk), mk.validationEmailInvalid);
    expect(Validators.password('short', mk), mk.validationPasswordTooShort);
    expect(Validators.price('abc', mk), mk.validationNumbersOnly);
    expect(Validators.minLength('ab', 3, mk), mk.validationTooShort(3));

    // And they really are translated, not English.
    expect(mk.validationEmailRequired, isNot(en.validationEmailRequired));
    expect(mk.validationTooShort(3), contains('3'));
  });

  test('valid input passes', () {
    expect(Validators.email('ana@example.com', en), isNull);
    expect(Validators.password('long enough', en), isNull);
    expect(Validators.price('1200', en), isNull);
    expect(Validators.minLength('Jacket', 3, en), isNull);
  });

  test('prices are kept sensible', () {
    expect(Validators.price('0', en), en.validationPriceTooLow);
    expect(Validators.price('100001', en), en.validationPriceTooHigh);
  });
}
