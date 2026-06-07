import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed, validated access to environment variables loaded from `.env`.
///
/// Call [Env.load] once during bootstrap before reading any value.
class Env {
  const Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  /// Optional — checkout is stubbed, so this may be a placeholder.
  static String get stripePublishableKey =>
      dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ?? '';

  /// True when Supabase has been pointed at a real project.
  static bool get isSupabaseConfigured =>
      !supabaseUrl.contains('YOUR-PROJECT-ref') &&
      supabaseAnonKey != 'your-anon-public-key';

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing env var "$key". Did you copy .env.example → .env?',
      );
    }
    return value;
  }
}
