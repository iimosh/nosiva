import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/features/listings/domain/listing_enums.dart';

void main() {
  test('a removed listing is recognised and is not for sale', () {
    expect(ListingStatus.fromValue('removed'), ListingStatus.removed);
    expect(ListingStatus.fromValue('active'), ListingStatus.active);
  });
}
