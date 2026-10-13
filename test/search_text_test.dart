import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/utils/search_text.dart';

void main() {
  test('wildcard characters are matched literally', () {
    expect(likeLiteral('100%'), r'100\%');
    expect(likeLiteral('h_m'), r'h\_m');
    expect(likeLiteral(r'a\b'), r'a\\b');
  });

  test('filter-syntax characters are dropped', () {
    expect(likeLiteral('red,blue'), 'redblue');
    expect(likeLiteral('x)or(y'), 'xory');
    expect(likeLiteral('"quoted" *'), 'quoted');
  });

  test('normal text is unchanged', () {
    expect(likeLiteral('  Zara  '), 'Zara');
    expect(likeLiteral('Скопје'), 'Скопје');
    expect(likeLiteral("Levi's 501"), "Levi's 501");
  });
}
