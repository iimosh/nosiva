import '../../l10n/app_localizations.dart';

/// Reusable form validators. Return null when valid, else a message in the
/// app's language. Use as `validator: (v) => Validators.email(v, context.l10n)`.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.validationEmailRequired;
    if (!_emailRegex.hasMatch(v)) return l10n.validationEmailInvalid;
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    final v = value ?? '';
    if (v.isEmpty) return l10n.validationPasswordRequired;
    if (v.length < 8) return l10n.validationPasswordTooShort;
    return null;
  }

  static String? price(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.validationPriceRequired;
    final parsed = double.tryParse(v);
    if (parsed == null) return l10n.validationNumbersOnly;
    if (parsed <= 0) return l10n.validationPriceTooLow;
    if (parsed > 100000) return l10n.validationPriceTooHigh;
    return null;
  }

  /// A phone number tidied for storage — spaces, dashes, dots and brackets
  /// removed, an optional leading + kept — or null when it isn't a plausible
  /// number (8–15 digits). Matches the database rule on buyer_phone.
  /// "070 123 456" → "070123456", "+389 70-123-456" → "+38970123456".
  static String? normalizePhone(String? value) {
    final cleaned = (value ?? '').trim().replaceAll(RegExp(r'[\s\-.()/]'), '');
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleaned) ? cleaned : null;
  }

  static String? minLength(String? value, int min, AppLocalizations l10n) {
    if ((value?.trim().length ?? 0) < min) return l10n.validationTooShort(min);
    return null;
  }
}
