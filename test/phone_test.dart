import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/utils/validators.dart';

void main() {
  test('phone numbers are tidied for the courier', () {
    expect(Validators.normalizePhone('070 123 456'), '070123456');
    expect(Validators.normalizePhone('+389 70-123-456'), '+38970123456');
    expect(Validators.normalizePhone('(02) 3123.456'), '023123456');
  });

  test('anything that is not a plausible number is refused', () {
    expect(Validators.normalizePhone(''), isNull);
    expect(Validators.normalizePhone('123'), isNull); // too short
    expect(Validators.normalizePhone('1234567890123456'), isNull); // too long
    expect(Validators.normalizePhone('070 ABC 456'), isNull);
    expect(Validators.normalizePhone('070123456; drop'), isNull);
    expect(Validators.normalizePhone('++38970123456'), isNull);
  });
}
