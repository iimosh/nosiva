import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Addresses of Nosiva's Neon backend, from the bundled .env file. All are
/// public (no secrets): access is controlled by sign-in tokens and the
/// database's security rules.
class Env {
  const Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get neonAuthUrl => _require('NEON_AUTH_URL');
  static String get neonDataApiUrl => _require('NEON_DATA_API_URL');
  static String get neonAuthReturnUrl => _require('NEON_AUTH_RETURN_URL');
  static String get neonMediaUrl => _require('NEON_MEDIA_URL');
  static String get neonPushUrl => _require('NEON_PUSH_URL');

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError('Missing env var "$key".');
    }
    return value;
  }
}
