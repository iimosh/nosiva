import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _currencyWhole = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  static String price(num value) {
    return value == value.roundToDouble()
        ? _currencyWhole.format(value)
        : _currency.format(value);
  }

  /// "just now", "5m", "3h", "2d", or a date for older items.
  static String timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(time);
  }

  static String chatTimestamp(DateTime time) => DateFormat('h:mm a').format(time);
}
