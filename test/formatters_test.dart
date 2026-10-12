import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nosiva/core/utils/formatters.dart';
import 'package:nosiva/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final mk = lookupAppLocalizations(const Locale('mk'));

  setUpAll(initializeDateFormatting);

  DateTime ago(Duration d) => DateTime.now().subtract(d);

  test('recent times read naturally in both languages', () {
    expect(Formatters.timeAgo(ago(const Duration(seconds: 20)), en), 'just now');
    expect(Formatters.timeAgo(ago(const Duration(seconds: 20)), mk), 'сега');
    expect(Formatters.timeAgo(ago(const Duration(minutes: 5)), en), '5m ago');
    expect(Formatters.timeAgo(ago(const Duration(minutes: 5)), mk), 'пред 5 мин');
    expect(Formatters.timeAgo(ago(const Duration(hours: 1, minutes: 5)), mk), 'пред 1 час');
    expect(Formatters.timeAgo(ago(const Duration(hours: 3)), mk), 'пред 3 часа');
    expect(Formatters.timeAgo(ago(const Duration(days: 1, hours: 1)), mk), 'пред 1 ден');
    expect(Formatters.timeAgo(ago(const Duration(days: 4)), mk), 'пред 4 дена');
  });

  test('older dates use the app language, with the year when needed', () {
    final lastYear = DateTime(DateTime.now().year - 1, 7, 3, 12);
    expect(Formatters.timeAgo(lastYear, mk), contains('јул'));
    expect(Formatters.timeAgo(lastYear, mk), contains('${lastYear.year}'));
    expect(Formatters.timeAgo(lastYear, en), contains('Jul'));
  });

  test('chat times use the 24-hour clock in local time', () {
    final utc = DateTime.utc(2026, 10, 8, 13, 45);
    final local = utc.toLocal();
    final expected =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    expect(Formatters.chatTimestamp(utc, mk), expected);
    expect(Formatters.chatTimestamp(utc, en), expected);
  });
}
