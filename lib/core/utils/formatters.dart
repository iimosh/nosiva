import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

abstract final class Formatters {
  static final _denar = NumberFormat.decimalPattern('mk');

  static String price(num value) {
    final rounded = value.round();
    return '${_denar.format(rounded)} ден';
  }

  /// "just now", "5m ago", "3h ago", "2d ago", then a date ("Jul 3", or
  /// "Jul 3, 2025" from another year) — all in the app's language.
  ///
  /// Times from the server are UTC; they're shown in the phone's time zone.
  static String timeAgo(DateTime time, AppLocalizations l10n) {
    final local = time.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    final format = local.year == now.year
        ? DateFormat.MMMd(l10n.localeName)
        : DateFormat.yMMMd(l10n.localeName);
    return format.format(local);
  }

  /// 24-hour clock ("15:45"), as used in Macedonia, in the phone's time zone.
  static String chatTimestamp(DateTime time, AppLocalizations l10n) =>
      DateFormat.Hm(l10n.localeName).format(time.toLocal());
}
