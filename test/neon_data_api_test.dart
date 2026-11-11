import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/backend/backend_providers.dart';

void main() {
  test('the Prefer header is cleaned for Neon', () {
    // What the data client sends when an update asks for the row back.
    expect(cleanPreferHeader(',return=representation'), 'return=representation');
    expect(cleanPreferHeader(' ,return=representation, ,count=exact'),
        'return=representation,count=exact');
    expect(cleanPreferHeader('return=minimal'), 'return=minimal');
    expect(cleanPreferHeader(' , '), '');
  });
}
