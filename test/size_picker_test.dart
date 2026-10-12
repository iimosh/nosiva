import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/features/listings/presentation/widgets/size_picker.dart';

void main() {
  group('SizePicker.normalize', () {
    test('accepts typical own sizes', () {
      expect(SizePicker.normalize('38'), '38');
      expect(SizePicker.normalize('W30 L32'), 'W30 L32');
      expect(SizePicker.normalize('One size'), 'One size');
      expect(SizePicker.normalize('Една големина'), 'Една големина');
      expect(SizePicker.normalize('36/38'), '36/38');
    });

    test('tidies spacing and matches letter sizes', () {
      expect(SizePicker.normalize('  w30   l32 '), 'w30 l32');
      expect(SizePicker.normalize('m'), 'M');
      expect(SizePicker.normalize('xxl'), 'XXL');
    });

    test('rejects empty, too long and wildcard/odd characters', () {
      expect(SizePicker.normalize('   '), isNull);
      expect(SizePicker.normalize('x' * 21), isNull);
      expect(SizePicker.normalize('38%'), isNull);
      expect(SizePicker.normalize('M_'), isNull);
      expect(SizePicker.normalize('<b>'), isNull);
    });
  });
}
