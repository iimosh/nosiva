/// Reusable form validators. Return null when valid, else an error message.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? price(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Price is required';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Enter numbers only';
    if (parsed <= 0) return 'Price must be more than 0';
    if (parsed > 100000) return 'Enter a lower price';
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'This'}) {
    if ((value?.trim().length ?? 0) < min) {
      return '$field should be at least $min characters';
    }
    return null;
  }
}
