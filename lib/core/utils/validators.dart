/// Reusable form validators. Return null when valid, else an error message.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'We need your email, bestie';
    if (!_emailRegex.hasMatch(v)) return 'That email looks a little off';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Pick a password';
    if (v.length < 8) return 'At least 8 characters please';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? price(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add a price';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Numbers only';
    if (parsed <= 0) return 'Price must be more than 0';
    if (parsed > 100000) return 'That seems a bit much 👀';
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'This'}) {
    if ((value?.trim().length ?? 0) < min) {
      return '$field should be at least $min characters';
    }
    return null;
  }
}
